=head1 NAME

HTML::Microformats::hAlarm - an hCalendar alarm component

=head1 SYNOPSIS

 use Data::Dumper;
 use HTML::Microformats::_context;
 use HTML::Microformats::hCalendar;

 my $context = HTML::Microformats::_context->new($dom, $uri);
 my @cals    = HTML::Microformats::hCalendar->extract_all(
                   $dom->documentElement, $context);
 foreach my $cal (@cals)
 {
   foreach my $ev ($cal->get_vevent)
   {
     foreach my $alarm ($ev->get_valarm)
     {
       print $alarm->get_description . "\n";
	   }
   }
 }

=head1 DESCRIPTION

HTML::Microformats::hAlarm is a helper module for HTML::Microformats::hCalendar.
This class is used to represent alarm components within calendars. Generally speaking,
you want to use HTML::Microformats::hCalendar instead.

HTML::Microformats::hAlarm inherits from HTML::Microformats::BASE. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::hAlarm;

use base qw(HTML::Microformats::BASE HTML::Microformats::Mixin::Parser);
use common::sense;
use 5.008;

our $VERSION = '0.00_13';

sub new
{
	my ($class, $element, $context) = @_;
	my $cache = $context->cache;
	
	return $cache->get($context, $element, $class)
		if defined $cache && $cache->get($context, $element, $class);
	
	my $self = {
		'element'    => $element ,
		'context'    => $context ,
		'cache'      => $cache ,
		'id'         => $context->make_bnode($element) ,
		};
	
	bless $self, $class;
	
	my $clone = $element->cloneNode(1);	
	$self->_expand_patterns($clone);
	$self->_simple_parse($clone);

	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub format_signature
{
	my $ical  = 'http://www.w3.org/2002/12/cal/icaltzd#';
	my $icalx = 'http://buzzword.org.uk/rdf/icaltzdx#';

	return {
		'root' => 'valarm',
		'classes' => [
			['action',       '?',  {'value-title'=>'allow'}],
			['attach',       'U?'],
			['attendee',     'M*', {'embedded'=>'hCard', 'is-in-cal'=>1}],
			['description',  '?'],
			['duration',     'D?'],
			['repeat',       'n?', {'value-title'=>'allow'}],
			['trigger',      'D?'] # TODO: should really allow 'related' subproperty and allow datetime values too. post-0.001
		],
		'options' => {
			'rel-enclosure'  => 'attach',
		},
		'rdf:type' => ["${ical}Valarm"] ,
		'rdf:property' => {
			'action'           => { 'literal'  => ["${ical}action"] } ,
			'attach'           => { 'resource' => ["${ical}attach"] } ,
			'attendee'         => { 'resource' => ["${ical}attendee"], 'literal'  => ["${icalx}attendee"] } ,
			'description'      => { 'literal'  => ["${ical}description"] } ,
			'duration'         => { 'literal'  => ["${ical}duration"] } ,
			'repeat'           => { 'literal'  => ["${ical}repeat"] , 'literal_datatype'=>'integer' } ,
			'trigger'          => { 'literal'  => ["${ical}trigger"] } ,
		},
	};
}

sub profiles
{
	return HTML::Microformats::hCalendar::profiles(@_);
}

1;


=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::hCalendar>,
L<HTML::Microformats::BASE>,
L<HTML::Microformats>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

