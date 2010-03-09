=head1 NAME

HTML::Microformats::Datatypes::DateTime - dates and datetimes

=head1 SYNOPSIS

 my $duration = HTML::Microformats::Datatypes::DateTime->now;
 print "$duration\n";

=cut

package HTML::Microformats::Datatypes::DateTime;

use base qw(DateTime);

use DateTime;
use DateTime::Format::Natural;
use DateTime::Format::Strptime;
use HTML::Microformats::Datatypes::DateTime::Parser;
use HTML::Microformats::Datatypes::String qw(isms);
use HTTP::Date;

=head1 DESCRIPTION

This class inherits from DateTime, so supports all of DateTime's methods.

=head2 Constructors

This class inherits from DateTime, so DateTime's standard constructors (C<new>,
C<now>, etc) should work. Also:

=over 4

=item C<< $dt = HTML::Microformats::Datatypes::DateTime->parse($string, $elem, $context, [$tz], [$base]) >>

Creates a new HTML::Microformats::Datatypes::DateTime object.

$tz is the timezone to use (if it can't be figured out) and $base is a base datetime to use for
relative datetimes, whatever that means.

=back

=cut

sub parse
{
	my $class  = shift;
	my $string = shift;
	my $elem   = shift||undef;
	my $page   = shift||undef;
	my $tz     = shift||undef;
	my $base   = shift||undef;
	
	return $class->_microformat_datetime($string, $tz, $base);
}

sub _microformat_datetime
{
	my $class = shift;
	
	my $dt    = $class->_microformat_datetime_helper(@_);
	
	# Super-dangerous: reblessing an already-blessed object.
	bless $dt, 'HTML::Microformats::Datatypes::DateTime';
}

sub _microformat_datetime_helper
# Very tolerant DateTime parsing. Microformats are supposed to always use W3CDTF,
# but we'll be lenient and do our best to parse other ISO 8601 formats, and if
# that fails, even try to parse natural language.
{
	my $class  = shift;
	my $string = shift;
	my $tz     = shift || 'UTC';
	my $base   = shift || undef;
	my $f;
	my $dt;
	
	$string = $string->{string} if (isms($string));
	
	my $parser = __PACKAGE__ . '::Parser';
	if ($base)
		{ $f = $parser->new(base_datetime => $base); }
	else
		{ $f = $parser->new; }
		
	eval {
		my $isostring = $string;
		$isostring =~ s/([\+\-]\d\d)([014][50])$/\1\:\2/;	
		$dt = $f->parse_datetime($isostring);
		$dt->{resolution} = $f->{resolution};
		
		if ($dt->{resolution} eq 'end')
		{
			$dt = $dt->add( days => 1 );
			$dt->{resolution} = 'day';
		}
	};
	
	unless ($dt)
	{
		eval {
			my $time = str2time($string);
			$dt = DateTime->from_epoch( epoch => $time );
			$dt->{resolution} = 'second' unless ($dt->{resolution});
		};
	}

	unless ($dt)
	{
		$f = DateTime::Format::Natural->new(
			lang          => 'en',        # Should read this from source input
			prefer_future => 1,
			daytime       => {
										morning    =>  9,
										afternoon  => 13,
										evening    => 20
								  },
			time_zone     => "$tz"
		);
		$dt = $f->parse_datetime($string);
		$dt->{resolution} = 'second' unless ($dt->{resolution});
	}
	return undef unless ($dt);
	
	my %pattern = (
	   year          => '%Y',
	   month         => '%Y-%m',
	   week          => '%F',
	   day           => '%F',
	   hour          => '%FT%H:%M',
	   minute        => '%FT%H:%M',
	   second        => '%FT%H:%M:%S',
	   nanosecond    => '%FT%T.%9N'
	);	
	my %tz_pattern = (
	   year          => '%Y',
	   month         => '%Y-%m',
	   week          => '%F',
	   day           => '%F',
	   hour          => '%FT%H:%M%z',
	   minute        => '%FT%H:%M%z',
	   second        => '%FT%H:%M:%S%z',
	   nanosecond    => '%FT%T.%9N%z'
	);
	
	if ($dt->year >= 100000)
	{
		foreach my $x (keys %pattern)
		{
			$pattern{$x}    = '+'.$pattern{$x};
			$tz_pattern{$x} = '+'.$tz_pattern{$x};
		}
	}
	elsif ($dt->year >= 10000)
	{
		foreach my $x (keys %pattern)
		{
			$pattern{$x}    = '+0'.$pattern{$x};
			$tz_pattern{$x} = '+0'.$tz_pattern{$x};
		}
	}

   if ($dt->{tz}->{name} eq 'floating')
   {
		$dt->set_formatter(DateTime::Format::Strptime->new(
			pattern => (  $pattern{$dt->{resolution}}  )
		));
	}
	else
	{
		$dt->set_formatter(DateTime::Format::Strptime->new(
			pattern => (  $tz_pattern{$dt->{resolution}}  )
		));
	}
	
	return $dt;
}


=head2 Public Methods

=over 4

=item C<< $d->datatype >>

Returns an the RDF datatype URI representing the data type of this literal.

=back

=cut

sub datatype
{
	my $self = shift;
	
	if($self->{datatype})
		{ return $self->{datatype}; }
	elsif ($self->{resolution} eq 'year')
		{ return 'http://www.w3.org/2001/XMLSchema#gYear'; }
	elsif ($self->{resolution} eq 'month')
		{ return 'http://www.w3.org/2001/XMLSchema#gYearMonth'; }
	elsif ($self->{resolution} eq 'day')
		{ return 'http://www.w3.org/2001/XMLSchema#date'; }
		
	return 'http://www.w3.org/2001/XMLSchema#dateTime';
}

sub TO_JSON
{
	return "$_[0]";
}

1;

__END__

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats>,
L<HTML::Microformats::Datatypes>,
L<DateTime>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut