=head1 NAME

HTML::Microformats::hTodo - an hCalendar todo component

=head1 SYNOPSIS

 use Data::Dumper;
 use HTML::Microformats::_context;
 use HTML::Microformats::hCalendar;

 my $context = HTML::Microformats::_context->new($dom, $uri);
 my @cals    = HTML::Microformats::hCalendar->extract_all(
                   $dom->documentElement, $context);
 foreach my $cal (@cals)
 {
   foreach my $todo ($cal->get_vtodo)
   {
     printf("%s: %s\n", $todo->get_due, $todo->get_summary);
   }
 }

=head1 DESCRIPTION

HTML::Microformats::hTodo is a helper module for HTML::Microformats::hCalendar.
This class is used to represent todo components within calendars. Generally speaking,
you want to use HTML::Microformats::hCalendar instead.

HTML::Microformats::hTodo inherits from HTML::Microformats::BASE. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::hTodo;

use base qw(HTML::Microformats::BASE HTML::Microformats::Mixin::Parser);
use common::sense;
use 5.008;

use HTML::Microformats::_util qw(stringify searchClass);

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
	$self->_parse_related($clone);

	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub _parse_related
{
	HTML::Microformats::hEvent::_parse_related(@_);
}

sub extract_all
{
	my ($class, $element, $context) = @_;
	
	my @todos = HTML::Microformats::BASE::extract_all($class, $element, $context);
	
	foreach my $list (searchClass('vtodo-list', $element))
	{
		push @todos, $class->extract_all_xoxo($list, $context);
	}
	
	return @todos;
}

sub format_signature
{
	my $ical  = 'http://www.w3.org/2002/12/cal/icaltzd#';
	my $icalx = 'http://buzzword.org.uk/rdf/icaltzdx#';

	return {
		'root' => 'vtodo',
		'classes' => [
			['attach',           'u*'],
			['attendee',         'M*',  {embedded=>'hCard !person', 'is-in-cal'=>1}],
			['categories',       '*'],
			['category',         '*',   {'use-key'=>'categories'}],
			['class',            '?'],
			['comment',          '*'],
			['completed',        'd?'],
			['contact',          'M*',  {embedded=>'hCard !person', 'is-in-cal'=>1}],
			['created',          'd?'],
			['description',      '?'],
			#['dtend',            'd?'],
			['dtstamp',          'd?'],
			['dtstart',          'd1'],
			['due',              'd?'],
			['duration',         'D?'],
			['exdate',           'd*'],
			['exrule',           'e*'],
			['geo',              'M*',  {embedded=>'geo'}],
			['last-modified',    'd?'],
			['location',         'M*',  {embedded=>'hCard adr geo'}],
			['organizer',        'M*',  {embedded=>'hCard !person', 'is-in-cal'=>1}],
			['percent-complete', '?'],
			['priority',         '?'],
			['rdate',            'd*'],
			['recurrance-id',    'U?'],
			['resource',         '*',   {'use-key'=>'resources'}],
			['resources',        '*'],
			['rrule',            'e*'],
			['sequence',         'n?'],
			['status',           '?'],
			['summary',          '1'],
			#['transp',           '?'],
			['uid',              'U?'],
			['url',              'U?'],
			['valarm',           'M*',  {embedded=>'hAlarm'}],
			['x-sighting-of',    'M*',  {embedded=>'species'}] #extension
		],
		'options' => {
			'rel-tag'       => 'categories',
			'rel-enclosure' => 'attach',
			'hmeasure'      => 'measures'
		},
		'rdf:type' => ["${ical}Vtodo"] ,
		'rdf:property' => {
			'attach'           => { 'resource' => ["${ical}attach"] } ,
			'attendee'         => { 'resource' => ["${ical}attendee"],  'literal'  => ["${icalx}attendee-literal"] } ,
			'categories'       => { 'resource' => ["${icalx}category"], 'literal'  => ["${ical}category"] },
			'class'            => { 'literal'  => ["${ical}class"] ,    'literal_datatype' => 'string'} ,
			'comment'          => { 'literal'  => ["${ical}comment"] } ,
			'completed'        => { 'literal'  => ["${ical}completed"] } ,
			'contact'          => { 'resource' => ["${icalx}contact"],  'literal'  => ["${ical}contact"] } ,
			'created'          => { 'literal'  => ["${ical}created"] } ,
			'description'      => { 'literal'  => ["${ical}description"] } ,
			'dtend'            => { 'literal'  => ["${ical}dtend"] } ,
			'dtstamp'          => { 'literal'  => ["${ical}dtstamp"] } ,
			'dtstart'          => { 'literal'  => ["${ical}dtstart"] } ,
			'due'              => { 'literal'  => ["${ical}due"] } ,
			'duration'         => { 'literal'  => ["${ical}duration"] } ,
			'exdate'           => { 'literal'  => ["${ical}exdate"] } ,
			'geo'              => { 'literal'  => ["${icalx}geo"] } ,
			'last-modified'    => { 'literal'  => ["${ical}lastModified"] } ,
			'location'         => { 'resource' => ["${icalx}location"], 'literal'  => ["${ical}location"] } ,
			'organizer'        => { 'resource' => ["${ical}organizer"], 'literal'  => ["${icalx}organizer-literal"] } ,
			'percent-complete' => { 'literal'  => ["${ical}percentComplete"] , 'literal_datatype' => 'integer' } ,
			'priority'         => { 'literal'  => ["${ical}priority"] } ,
			'rdate'            => { 'literal'  => ["${ical}rdate"] } ,
			'recurrance-id'    => { 'resource' => ["${ical}recurranceId"] , 'literal'  => ["${ical}recurranceId"] , 'literal_datatype' => 'string' } ,
			'resources'        => { 'literal'  => ["${ical}resources"] } ,
			'sequence'         => { 'literal'  => ["${ical}sequence"] , 'literal_datatype' => 'integer' } ,
			'status'           => { 'literal'  => ["${ical}status"] ,   'literal_datatype' => 'string' } ,
			'summary'          => { 'literal'  => ["${ical}summary"] } ,
			'transp'           => { 'literal'  => ["${ical}transp"] ,   'literal_datatype' => 'string' } ,
			'uid'              => { 'resource' => ["${ical}uid"] ,      'literal'  => ["${ical}uid"] , 'literal_datatype' => 'string' } ,
			'url'              => { 'resource' => ["${ical}url"] } ,
			'valarm'           => { 'resource' => ["${ical}valarm"] } ,
			'x-sighting-of'    => { 'resource' => ["${ical}x-sighting-of"] } ,
		},
	};
}

sub add_to_model
{
	# essentially the same...
	return HTML::Microformats::hEvent::add_to_model(@_);
}

sub profiles
{
	return HTML::Microformats::hCalendar::profiles(@_);
}

sub extract_all_xoxo
{
	my ($class, $element, $context) = @_;
	
	return qw() unless $element->tagName =~ /^(ul|ol)$/i;
	
	my @all_items;
	foreach my $li ($element->getChildrenByTagName('li'))
	{
		my @these_items = $class->extract_all_xoxo_item($li, $context);
		push @all_items, @these_items;
	}
		
	return @all_items;
}

sub extract_all_xoxo_item
{
	my ($class, $element, $context) = @_;
	
	return qw() unless $element->tagName eq 'li';
	
	my $clone = $element->cloneNode(1);

	# Find any child XOXO-style lists. Parse then discard.
	my @child_items;
	foreach my $list ($clone->getChildrenByTagName('ol'))
	{
		my @these_items = $class->extract_all_xoxo($list, $context);
		push @child_items, @these_items;
		$clone->removeChild($list);
	}
	foreach my $list ($clone->getChildrenByTagName('ul'))
	{
		my @these_items = $class->extract_all_xoxo($list, $context);
		push @child_items, @these_items;
		$clone->removeChild($list);
	}

	my $self = $class->new($clone, $context);
	unless (length $self->data->{'summary'})
	{
		$self->data->{'summary'} = stringify($clone);
	}
	
	my @rv = ($self);
	CHILD: foreach my $child (@child_items)
	{
		if (defined $child->{'related'}->{'parent'}
		or defined $child->{'DATA'}->{'parent'})
		{
			push @{$child->{'related'}->{'other'}}, $self;
			push @{$self->{'related'}->{'other'}}, $child;
		}
		else
		{
			$child->{'related'}->{'parent'} = $self;
			push @{$self->{'related'}->{'child'}}, $child;
		}
		
		OTHERCHILD: foreach my $other_child (@child_items)
		{
			next OTHERCHILD if $child == $other_child;
			push @{$child->{'related'}->{'sibling'}}, $other_child;
		}
		
		push @rv, $child;
	}
	
	return @rv;
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
