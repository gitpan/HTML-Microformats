=head1 NAME

HTML::Microformats::Datatypes::Interval - concrete periods of time

=head1 SYNOPSIS

 my $interval = HTML::Microformats::Datatypes::Interval->new($span);
 print "$interval\n";

=cut

package HTML::Microformats::Datatypes::Interval;

use overload '""'=>\&to_string, '<=>'=>\&compare, 'cmp'=>\&compare;
use common::sense;

use base qw(Exporter);
our @EXPORT    = qw();
our @EXPORT_OK = qw(compare);

use DateTime::Span;
use HTML::Microformats::_simple_parser;
use HTML::Microformats::Datatypes::Duration;

=head1 DESCRIPTION

=head2 Constructors

=over 4

=item C<< $i = HTML::Microformats::Datatypes::Interval->new($span) >>

Creates a new HTML::Microformats::Datatypes::Interval object.

$span is a DateTime::Span object.

=cut

sub new
{
	my $class        = shift;
	my $interval_obj = shift;
	my $this         = {};
	$this->{i}       = $interval_obj;
	
	bless $this, $class;
	return $this;
}

=item C<< $i = HTML::Microformats::Datatypes::Interval->parse($string, $elem, $context) >>

Creates a new HTML::Microformats::Datatypes::Interval object.

$string is an interval represented in ISO 8601 format, for example:
'2010-01-01/P1Y' or '2010-01-01/2011-01-01'. $elem is the
XML::LibXML::Element being parsed. $context is the document
context.

This constructor supports a number of experimental microformat
interval patterns. e.g.

 <div class="interval">
  <span class="d">4</span> days starting from
  <abbr class="start" title="2010-01-01">2010</abbr>
 </div>

=back

=cut

sub parse
{
	my $class  = shift;
	my $string = shift;
	my $elem   = shift||undef;
	my $page   = shift||undef;
	my $rv     = {};
	
	if ($string =~ /^ \s* (.+) \s* \/ \s* (.+) \s* $/x)
	{
		my $one = $1;
		my $two = $2;
		
		if ($one =~ /^P/i && $two !~ /^P/i)
		{
			my $duration = HTML::Microformats::Datatypes::Duration->parse($one, $elem, $page);
			my $before   = HTML::Microformats::Datatypes::DateTime->parse($two, $elem, $page);
			
			if ($duration && $before)
			{
				my $span = DateTime::Span->from_datetime_and_duration(
					duration => $duration->{d},
					before   => $before
				);
				$rv->{i} = $span if ($span);
			}			
		}
		elsif ($one !~ /^P/i && $two !~ /^P/i)
		{
			my $start    = HTML::Microformats::Datatypes::DateTime->parse($one, $elem, $page);
			my $before   = HTML::Microformats::Datatypes::DateTime->parse($two, $elem, $page, undef, $start);
			
			if ($start && $before)
			{
				my $span = DateTime::Span->from_datetimes(
					start   => $start,
					before  => $before
				);
				$rv->{i} = $span if ($span);
			}
		}
		elsif ($one !~ /^P/i && $two =~ /^P/i)
		{
			my $start    = HTML::Microformats::Datatypes::DateTime->parse($one, $elem, $page);
			my $duration = HTML::Microformats::Datatypes::Duration->parse($two, $elem, $page);

			if ($duration && $start)
			{
				my $span = DateTime::Span->from_datetime_and_duration(
					duration => $duration->{d},
					start    => $start
				);
				$rv->{i} = $span if ($span);
			}			
		}
	}
	
	if (! $rv->{i})
	{
		my $duration = HTML::Microformats::Datatypes::Duration->parse(undef, $elem, $page);
		
		my $time     = {};
		PROP: foreach my $prop (qw(start after))
		{
			my @nodes = searchClass($prop, $elem);
			NODE: foreach my $n (@nodes)
			{
				$time->{$prop} = HTML::Microformats::Datatypes::DateTime->parse(
					HTML::Microformats::_simple_parser->stringify($nodes[0], undef, 1),
					$nodes[0], $page);
				last NODE if ($time->{$prop});
			}
		}
		PROP: foreach my $prop (qw(end before))
		{
			my @nodes = searchClass($prop, $elem);
			NODE: foreach my $n (@nodes)
			{
				$time->{$prop} = HTML::Microformats::Datatypes::DateTime->parse(
					HTML::Microformats::_simple_parser->stringify($nodes[0], undef, 1),
					$nodes[0],
					$page,
					undef,
					($time->{start} || $time->{after})
				);
				last NODE if ($time->{$prop});
			}
		}

		if (($time->{start}||$time->{after})
		&&  ($time->{end}||$time->{before}))
		{
			my $startlabel = ($time->{start}) ? 'start' : 'after';
			my $endlabel   = ($time->{end})   ? 'end'   : 'before';
			
			my $span = DateTime::Span->from_datetimes(
				$startlabel  => ($time->{start}||$time->{after}),
				$endlabel    => ($time->{end}||$time->{before})
			);
			$rv->{i} = $span if ($span);
		}
		
		elsif (($time->{start}||$time->{after})
		&&     ($duration))
		{
			my $startlabel = ($time->{start}) ? 'start' : 'after';
			
			my $span = DateTime::Span->from_datetime_and_duration(
				$startlabel  => ($time->{start}||$time->{after}),
				duration     => $duration->{d}
			);
			$rv->{i} = $span if ($span);
		}

		elsif (($duration)
		&&     ($time->{end}||$time->{before}))
		{
			my $endlabel   = ($time->{end})   ? 'end'   : 'before';
			
			my $span = DateTime::Span->from_datetime_and_duration(
				duration     => $duration->{d},
				$endlabel    => ($time->{end}||$time->{before})
			);
			$rv->{i} = $span if ($span);
		}
		
	}

	if ($rv->{i})
	{
		$rv->{string} = $string;
		bless $rv, $class;
		return $rv;
	}
	
	return undef;
}

=head2 Public Methods

=over 4

=item C<< $span = $i->span >>

Returns a DateTime::Span object.

=cut

sub span
{
	my $this = shift;
	return $this->{i}
}

=item C<< $span = $i->to_string >>

Returns an ISO 8601 formatted string representing the interval.

=back

=cut

sub to_string
{
	my $this = shift;
	my $D    = HTML::Microformats::Datatypes::Duration->new($this->{i}->duration);
	
	return $this->{i}->start.'/'."$D";
}

=head2 Function

=over 4

=item C<< compare($a, $b) >>

Compares intervals $a and $b. Return values are as per 'cmp' (see L<perlfunc>).

This function is not exported by default.

Can also be used as a method:

 $a->compare($b);

=back

=cut

sub compare
{
	my $this = shift;
	my $that = shift;
	return ("$this" cmp "$that");
}

1;

__END__

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats>,
L<HTML::Microformats::Datatypes>,
L<DateTime::Span>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
