=head1 NAME

HTML::Microformats::Datatypes::Duration - floating periods of time

=head1 SYNOPSIS

 my $duration = HTML::Microformats::Datatypes::Duration->new($d);
 print "$duration\n";

=cut

package HTML::Microformats::Datatypes::Duration;

use common::sense;
use overload '""'=>\&to_string, '+'=>\&add, '-'=>\&subtract, '<=>'=>\&compare, 'cmp'=>\&compare;

use base qw(Exporter);
our @EXPORT    = qw();
our @EXPORT_OK = qw(compare add subtract);

use DateTime;
use DateTime::Duration;
use HTML::Microformats::_simple_parser;
use HTML::Microformats::_util qw(searchClass stringify);

=head1 DESCRIPTION

=head2 Constructors

=over 4

=item C<< $duration = HTML::Microformats::Datatypes::Duration->new($d) >>

Creates a new HTML::Microformats::Datatypes::Duration object.

$span is a DateTime::Duration object.

=cut

sub new
{
	my $class        = shift;
	my $duration_obj = shift;
	my $this         = {};
	$this->{d}       = $duration_obj;
	
	bless $this, $class;
	return $this;
}

=item C<< $i = HTML::Microformats::Datatypes::Duration->parse($string, $elem, $context) >>

Creates a new HTML::Microformats::Datatypes::Duration object.

$string is an duration represented in ISO 8601 format, for example:
'P1Y' or 'PT2H29M58.682S'. $elem is the XML::LibXML::Element
being parsed. $context is the document context.

This constructor supports a number of experimental microformat
duration patterns. e.g.

 <div class="duration">
  <span class="d">4</span> days.
 </div>

=back

=cut

sub parse
{
	my $class  = shift;
	my $string = shift;
	my $elem   = shift||undef;
	my $page   = shift||undef;
	my $pkg    = __PACKAGE__;
	
	# Try for nested class='s', class='min', class='h', etc. Standard=ISO-31.
	if ($elem)
	{
		my ($d, $h, $min, $s, $n);
		my $success = 0;
		my $X = {};
		
		# Find values.
		no strict;
		foreach my $x (qw(d h min s))
		{
			my @tmp = searchClass($x, $elem);
			if (@tmp)
			{
				my $y = stringify($tmp[0], {'abbr-pattern'=>1});
				$y    =~ s/\,/\./;
				$X->{$x} = "$y";  # MagicString -> string.
				$success++;
			}
		}
		
		if ($success)
		{
			# Cope with fractions.
			foreach my $frac (qw(d=24.h h=60.min min=60.s s=1000000000.n))
			{
				my ($big, $mult, $small) = split /[\=\.]/, $frac;
				next unless ($X->{$big} =~ /\./);
				
				my $int_part  = int($X->{$big});
				my $frac_part = $X->{$big} - $int_part;
				
				$X->{$big}    =  $int_part;
				$X->{$small} += ($mult * $frac_part);
			}
			use strict;
			$X->{'n'} = int($X->{'n'});
	
			# Construct and return object.
			my $dur = DateTime::Duration->new(
				days        => $X->{'d'}||0,
				hours       => $X->{'h'}||0,
				minutes     => $X->{'min'}||0,
				seconds     => $X->{'s'}||0,
				nanoseconds => $X->{'n'}||0
			);
			my $rv = new(__PACKAGE__, $dur);
			$rv->{string}  = $string;
			$rv->{element} = $elem;
			return $rv;
		}
	}

	# Commas as decimal points.
	my $string2 = $string;
	$string2 =~ s/\,/\./g;	
	
	# Standard=ISO-8601.
	if ($string2 =~ /^
			\s*
			([\+\-])?          # Potentially negitive...
			P                  # Period of...
			(?:([\d\.]*)Y)?    # n Years
			(?:([\d\.]*)M)?    # n Months
			(?:([\d\.]*)W)?    # n Weeks
			(?:([\d\.]*)D)?    # n Days
			(?:                 
				T               # And a time of...
				(?:([\d\.]*)H)? # n Hours
				(?:([\d\.]*)M)? # n Minutes
				(?:([\d\.]*)S)? # n Seconds
			)?
			\s*
			/ix)
	{
		my $X = {};
		$X->{'I'}   = $1;
		$X->{'y'}   = $2;
		$X->{'m'}   = $3;
		$X->{'w'}   = $4;
		$X->{'d'}   = $5;
		$X->{'h'}   = $6;
		$X->{'min'} = $7;
		$X->{'s'}   = $8;
		$X->{'n'}   = 0;
		
		# Handle fractional
		no strict;
		foreach my $frac (qw(y=12.m m=30.d w=7.d d=24.h h=60.min min=60.s s=1000000000.n))
		{
			my ($big, $mult, $small) = split /[\=\.]/, $frac;
			next unless ($X->{$big} =~ /\./);
			
			my $int_part  = int($X->{$big});
			my $frac_part = $X->{$big} - $int_part;
			
			$X->{$big}    =  $int_part;
			$X->{$small} += ($mult * $frac_part);
		}
		use strict;
		$X->{'n'} = int($X->{'n'});
		
		# Construct and return object.
		my $dur = DateTime::Duration->new(
			years       => $X->{'y'}||0,
			months      => $X->{'m'}||0,
			weeks       => $X->{'w'}||0,
			days        => $X->{'d'}||0,
			hours       => $X->{'h'}||0,
			minutes     => $X->{'min'}||0,
			seconds     => $X->{'s'}||0,
			nanoseconds => $X->{'n'}||0
		);
		my $rv = $X->{'I'} eq '-' ? $pkg->new($dur->inverse) 
		                          : $pkg->new($dur);
		$rv->{string}  = $string;
		$rv->{element} = $elem;
		return $rv;
	}
	
	# Duration as a simple number of seconds. Standard=SI.
	elsif ($string2 =~ /^\s* (\-?)(\d*)(?:\.(\d+))? \s* S? \s*$/ix && ($1||$2))
	{
		my $s = $2;
		my $n = "0.$3" * 1000000000;
		
		# Construct and return object.
		my $dur = DateTime::Duration->new(
			seconds     => $s,
			nanoseconds => $n
		);
		my $rv = $1 eq '-' ? $pkg->new($dur->inverse) 
		                   : $pkg->new($dur);
		$rv->{string}  = $string;
		$rv->{element} = $elem;
		return $rv;
	}

##TODO
#	# Look for hMeasure.
#	elsif ($elem && $page)
#	{
#		# By this point, we're on a clone of the element, and certain class data
#		# within it may have been destroyed. This is a little hack to find our
#		# way back to the *real* element!
#		my $real;
#		my @real = $page->{DOM}->findnodes($elem->getAttribute('_xpath'));
#		$real = $real[0] if (@real);
#		return $string unless ($real);
#		
#		my @measures;
#		if ($real->getAttribute('class') =~ /\b(hmeasure)\b/)
#			{ push @measures, Swignition::uF::hMeasure::parse($page, $real); }
#		else
#			{ @measures = Swignition::uF::hMeasure::parse_all($page, $real); }
#			
#		foreach my $m (@measures)
#		{
#			next if ($m->{item});
#			next if ($m->{type} && ($m->{type} !~ /^\s*(duration)\s*$/i));
#			
#			my ($dur, $neg);
#			my $n = $m->{num};
#			$n = "$n"; # MagicString -> string
#			if ($n < 0)
#			{
#				$neg = 1;
#				$n   = 0 - $n;
#			}
#			
#			if ($m->{unit} && ($m->{unit} =~ /^\s* s ( ec (ond)? s? )? \s*$/ix))
#			{
#				print "hMeasure duration in seconds.\n";
#				my $seconds     = int($n); $n -= $seconds; $n *= 1000000000;
#				my $nanoseconds = int($n);
#		
#				# Construct and return object.
#				$dur = DateTime::Duration->new(
#					seconds     => $seconds,
#					nanoseconds => $nanoseconds
#				);
#			}
#			
#			elsif ($m->{unit} && ($m->{unit} =~ /^\s* min ( (ute)? s? )? \s*$/ix))
#			{
#				print "hMeasure duration in minutes.\n";
#				my $minutes     = int($n); $n -= $minutes; $n *= 60;
#				my $seconds     = int($n); $n -= $seconds; $n *= 1000000000;
#				my $nanoseconds = int($n);
#		
#				# Construct and return object.
#				$dur = DateTime::Duration->new(
#				   minutes     => $minutes,
#					seconds     => $seconds,
#					nanoseconds => $nanoseconds
#				);
#			}
#
#			elsif ($m->{unit} && ($m->{unit} =~ /^\s* h ( our s? )? \s*$/ix))
#			{
#				print "hMeasure duration in hours.\n";
#				my $hours       = int($n); $n -= $hours;   $n *= 60;
#				my $minutes     = int($n); $n -= $minutes; $n *= 60;
#				my $seconds     = int($n); 
#		
#				# Construct and return object.
#				$dur = DateTime::Duration->new(
#				   hours       => $hours,
#				   minutes     => $minutes,
#					seconds     => $seconds
#				);
#			}
#
#			elsif ($m->{unit} && ($m->{unit} =~ /^\s* d ( ay s? )? \s*$/ix))
#			{
#				print "hMeasure duration in days.\n";
#				my $days        = int($n); $n -= $days;    $n *= 24;
#				my $hours       = int($n); $n -= $hours;   $n *= 60;
#				my $minutes     = int($n); $n -= $minutes; $n *= 60;
#				my $seconds     = int($n); 
#		
#				# Construct and return object.
#				$dur = DateTime::Duration->new(
#				   days        => $days,
#				   hours       => $hours,
#				   minutes     => $minutes,
#					seconds     => $seconds
#				);
#			}
#			
#			if ($dur)
#			{
#				my $rv = ($neg==1) ? Swignition::MagicDuration->new($dur->inverse) 
#		                         : Swignition::MagicDuration->new($dur);
#				$rv->{string}   = $string;
#				$rv->{element}  = $elem;
#				$rv->{hmeasure} = $m;
#				return $rv;
#			}
#		}
#	}
	
	return $string;
}

=head2 Public Methods

=over 4

=item C<< $d = $duration->duration >>

Returns a DateTime::Duration object.

=cut

sub duration
{
	my $this = shift;
	return $this->{d}
}

=item C<< $d->to_string >>

Returns an ISO 8601 formatted string representing the duration.

=back

=cut

sub to_string
{
	my $self = shift;
	my $str;
	
	# We coerce weeks into days and nanoseconds into fractions of a second
	# for compatibility with xsd:duration.
	
	if ($self->{d}->is_negative)
		{ $str .= '-P'; }
	else
		{ $str .= 'P'; }
		
	if ($self->{d}->years)
		{ $str .= $self->{d}->years.'Y'; }

	if ($self->{d}->months)
		{ $str .= $self->{d}->months.'M'; }

	if ($self->{d}->weeks || $self->{d}->days)
		{ $str .= ($self->{d}->days + (7 * $self->{d}->weeks)).'D'; }

	$str .= 'T';

	if ($self->{d}->hours)
		{ $str .= $self->{d}->hours.'H'; }

	if ($self->{d}->minutes)
		{ $str .= $self->{d}->minutes.'M'; }

	if ($self->{d}->seconds || $self->{d}->nanoseconds)
		{ $str .= ($self->{d}->seconds + ($self->{d}->nanoseconds / 1000000000)).'S'; }
		
	$str =~ s/T$//;
	
	return $str;
}

=head2 Functions

=over 4

=item C<< compare($a, $b) >>

Compares durations $a and $b. Return values are as per 'cmp' (see L<perlfunc>).

Note that there is not always a consistent answer when comparing durations. 30 days
is longer than a month in February, but shorter than a month in January. Durations
are compared as if they were applied to the current datetime (i.e. now).

This function is not exported by default.

Can also be used as a method:

 $a->compare($b);

=cut

sub compare
{
	my $this = shift;
	my $that = shift;
	return DateTime::Duration->compare($this->{d}, $that->{d}, DateTime->now);
}

=item C<< $c = add($a, $b) >>

Adds two durations together.

This function is not exported by default.

Can also be used as a method:

 $c = $a->add($b);

=cut

sub add
{
	my $this = shift;
	my $that = shift;
	my $sign = shift || '+';
	
	my $rv = $this->{d}->clone;
	if ($sign eq '-')
		{ $rv -= $that->{d}; }
	else
		{ $rv += $that->{d}; }
	
	return new(__PACKAGE__, $rv);
}

=item C<< $c = subtract($a, $b) >>

Subtracts duration $b from $a.

This function is not exported by default.

Can also be used as a method:

 $c = $a->subtract($b);

=back

=cut

sub subtract
{
	return add(@_, '-');
}

1;

__END__

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats>,
L<HTML::Microformats::Datatypes>,
L<DateTime::Duration>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut