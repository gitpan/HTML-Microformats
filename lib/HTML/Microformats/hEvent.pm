=head1 NAME

HTML::Microformats::hEvent - an hCalendar event component

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
     printf("%s: %s\n", $ev->get_dtstart, $ev->get_summary);
   }
 }

=head1 DESCRIPTION

HTML::Microformats::hEvent is a helper module for HTML::Microformats::hCalendar.
This class is used to represent event components within calendars. Generally speaking,
you want to use HTML::Microformats::hCalendar instead.

HTML::Microformats::hEvent inherits from HTML::Microformats::BASE. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::hEvent;

use base qw(HTML::Microformats::BASE HTML::Microformats::Mixin::Parser);
use common::sense;
use 5.008;

use HTML::Microformats::_util qw(searchClass searchRel stringify);
use HTML::Microformats::species;

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
	
	# Embedded species - too tricky for _simple_parse().
	my @nested = searchClass(HTML::Microformats::species->format_signature->{'root'}, $clone);
	foreach my $h (@nested)
	{
		if ($h->getAttribute('class') =~ / (^|\s) (attendee) (\s|$) /x)
		{
			push @{ $self->{'DATA'}->{'x-sighting-of'} }, HTML::Microformats::species->new($h, $context);
		}
		my $newClass = $h->getAttribute('class');
		$newClass =~ s/\b(attendee|x.sighting.of)\b//g;
		$h->setAttribute('class', $newClass);
	}
	
	$self->_simple_parse($clone);
	
	$self->_parse_related($clone);

	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub _parse_related
{
	my ($self, $element) = @_;
	
	# Related-to - too tricky for simple_parse()
	my @relations = searchClass('related-to', $element);
	foreach my $r (@relations)
	{
		if ($r->tagName !~ /^(a|area|link)$/i)
		{
			push @{$self->{'DATA'}->{'sibling'}}, stringify($r, 'value');
		}
		elsif ($r->getAttribute('rel') =~ /vcalendar-parent/i && !defined $self->{'DATA'}->{'parent'})
		{
			$self->{'DATA'}->{'parent'} = $self->context->uri($r->getAttribute('href'));
		}
		elsif ($r->getAttribute('rel') =~ /vcalendar-child/i)
		{
			push @{$self->{'DATA'}->{'child'}}, $self->context->uri($r->getAttribute('href'));
		}
		else
		{
			push @{$self->{'DATA'}->{'sibling'}}, $self->context->uri($r->getAttribute('href'));
		}
	}

	# If no parent, then try to find a link with rel="vcalendar-parent" but no
	# class="related-to".
	unless ($self->{'DATA'}->{'parent'})
	{
		@relations = searchRel('vcalendar-parent', $element);
		my $r = shift @relations;
		$self->{'DATA'}->{'parent'} = $self->context->uri($r->getAttribute('href')) if ($r);
	}
	
	# Find additional siblings.
	@relations = searchRel('vcalendar-sibling', $element);
	foreach my $r (@relations)
	{
		push @{$self->{'DATA'}->{'sibling'}}, $self->context->uri($r->getAttribute('href'))
			unless $r->getAttribute('class') =~ /\b(related-to)\b/;
	}
	
	# Find additional children.
	@relations = searchRel('vcalendar-child', $element);
	foreach my $r (@relations)
	{
		push @{$self->{'DATA'}->{'child'}}, $self->context->uri($r->getAttribute('href'))
			unless $r->getAttribute('class') =~ /\b(related-to)\b/;
	}
	
	return $self;
}

sub format_signature
{
	my $ical  = 'http://www.w3.org/2002/12/cal/icaltzd#';
	my $icalx = 'http://buzzword.org.uk/rdf/icaltzdx#';

	return {
		'root' => 'vevent',
		'classes' => [
			['attach',           'u*'],
			['attendee',         'M*',  {embedded=>'hCard !person', 'is-in-cal'=>1}],
			['categories',       '*'],
			['category',         '*',   {'use-key'=>'categories'}],
			['class',            '?',   {'value-title'=>'allow'}],
			['comment',          '*'],
			#['completed',        'd?'],
			['contact',          'M*',  {embedded=>'hCard !person', 'is-in-cal'=>1}],
			['created',          'd?'],
			['description',      '?'],
			['dtstamp',          'd?'],
			['dtstart',          'd1'],
			['dtend',            'd?',  {'datetime-feedthrough' => 'dtstart'}],
			#['due',              'd?'],
			['duration',         'D?'],
			['exdate',           'd*'],
			['exrule',           'e*'],
			['geo',              'M*',  {embedded=>'geo'}],
			['last-modified',    'd?'],
			['location',         'M*',  {embedded=>'hCard adr geo'}],
			['organizer',        'M*',  {embedded=>'hCard !person', 'is-in-cal'=>1}],
			#['percent-complete', '?'],
			['priority',         '?',   {'value-title'=>'allow'}],
			['rdate',            'd*'],
			['recurrance-id',    'U?'],
			['resource',         '*',   {'use-key'=>'resources'}],
			['resources',        '*'],
			['rrule',            'e*'],
			['sequence',         'n?',  {'value-title'=>'allow'}],
			['status',           '?',   {'value-title'=>'allow'}],
			['summary',          '1'],
			['transp',           '?',   {'value-title'=>'allow'}],
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
		'rdf:type' => ["${ical}Vevent"] ,
		'rdf:property' => {
			'attach'           => { 'resource' => ["${ical}attach"] } ,
			'attendee'         => { 'resource' => ["${ical}attendee"],  'literal'  => ["${icalx}attendee-literal"] } ,
			'categories'       => { 'resource' => ["${icalx}category"], 'literal'  => ["${ical}category"] },
			'class'            => { 'literal'  => ["${ical}class"] ,    'literal_datatype' => 'string'} ,
			'comment'          => { 'literal'  => ["${ical}comment"] } ,
			'contact'          => { 'resource' => ["${icalx}contact"],  'literal'  => ["${ical}contact"] } ,
			'created'          => { 'literal'  => ["${ical}created"] } ,
			'description'      => { 'literal'  => ["${ical}description"] } ,
			'dtend'            => { 'literal'  => ["${ical}dtend"] } ,
			'dtstamp'          => { 'literal'  => ["${ical}dtstamp"] } ,
			'dtstart'          => { 'literal'  => ["${ical}dtstart"] } ,
			'duration'         => { 'literal'  => ["${ical}duration"] } ,
			'exdate'           => { 'literal'  => ["${ical}exdate"] } ,
			'geo'              => { 'literal'  => ["${icalx}geo"] } ,
			'last-modified'    => { 'literal'  => ["${ical}lastModified"] } ,
			'location'         => { 'resource' => ["${icalx}location"], 'literal'  => ["${ical}location"] } ,
			'organizer'        => { 'resource' => ["${ical}organizer"], 'literal'  => ["${icalx}organizer-literal"] } ,
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
	my $self  = shift;
	my $model = shift;

	my $ical  = 'http://www.w3.org/2002/12/cal/icaltzd#';
	
	$self->_simple_rdf($model);
	_add_to_model_geo($self, $model);
	_add_to_model_related($self, $model);

	foreach my $prop (qw(exrule rrule))
	{
		foreach my $val ( @{ $self->data->{$prop} } )
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new("${ical}${prop}"),
				RDF::Trine::Node::Blank->new(substr($val->{'_id'},2)),
				));
			$val->add_to_model($model);
		}
	}

	return $self;
}

sub _add_to_model_geo
{
	my ($self, $model) = @_;
	
	my $ical  = 'http://www.w3.org/2002/12/cal/icaltzd#';
	
	# GEO is an rdf:List of floating point numbers :-(
	foreach my $geo (@{ $self->data->{'geo'} })
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${ical}geo"),
			$geo->id(1, 'ical-list.0'),
			));	
		$model->add_statement(RDF::Trine::Statement->new(
			$geo->id(1, 'ical-list.0'),
			RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"),
			RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#List"),
			));	
		$model->add_statement(RDF::Trine::Statement->new(
			$geo->id(1, 'ical-list.0'),
			RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#first"),
			RDF::Trine::Node::Literal->new($geo->data->{'latitude'}, undef, 'http://www.w3.org/2001/XMLSchema#float'),
			));	
		$model->add_statement(RDF::Trine::Statement->new(
			$geo->id(1, 'ical-list.0'),
			RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#next"),
			$geo->id(1, 'ical-list.1'),
			));	
		$model->add_statement(RDF::Trine::Statement->new(
			$geo->id(1, 'ical-list.1'),
			RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"),
			RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#List"),
			));	
		$model->add_statement(RDF::Trine::Statement->new(
			$geo->id(1, 'ical-list.1'),
			RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#first"),
			RDF::Trine::Node::Literal->new($geo->data->{'longitude'}, undef, 'http://www.w3.org/2001/XMLSchema#float'),
			));	
		$model->add_statement(RDF::Trine::Statement->new(
			$geo->id(1, 'ical-list.1'),
			RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#next"),
			RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#nil"),
			));	
	}
}

sub _add_to_model_related
{
	my ($self, $model) = @_;
	
	my $ical  = 'http://www.w3.org/2002/12/cal/icaltzd#';
	
	foreach my $relationship (qw(parent child sibling other))
	{
		my @uids;
		if (ref $self->data->{$relationship} eq 'ARRAY')
		{
			@uids = @{$self->data->{$relationship}};
		}
		else
		{
			push @uids, $self->data->{$relationship};
		}
		
		for (my $i=0; defined $uids[$i]; $i++)
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new("${ical}relatedTo"),
				$self->id(1, "relationship.${relationship}.${i}"),
				));	
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, "relationship.${relationship}.${i}"),
				RDF::Trine::Node::Resource->new("${ical}reltype"),
				RDF::Trine::Node::Literal->new($relationship, undef, 'http://www.w3.org/2001/XMLSchema#string'),
				));
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, "relationship.${relationship}.${i}"),
				RDF::Trine::Node::Resource->new("http://buzzword.org.uk/rdf/icaltzdx#related-component-uid"),
				RDF::Trine::Node::Literal->new($uids[$i]),
				));
		}
		
		my @objects;
		if (ref $self->{'related'}->{$relationship} eq 'ARRAY')
		{
			@objects = @{$self->{'related'}->{$relationship}};
		}
		else
		{
			push @objects, $self->{'related'}->{$relationship};
		}
		for (my $i=0; defined $objects[$i]; $i++)
		{
			next unless ref $objects[$i];
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new("http://buzzword.org.uk/rdf/icaltzdx#${relationship}-component"),
				$objects[$i]->id(1),
				));	
		}
	}
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
