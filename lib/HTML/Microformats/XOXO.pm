package HTML::Microformats::XOXO;

use base qw(HTML::Microformats::BASE);
use common::sense;
use 5.008;

use HTML::Microformats::_util qw(stringify xml_stringify);
use JSON qw/to_json/;

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
		};	
	bless $self, $class;
	
	if ($element->hasAttribute('id') && length $element->getAttribute('id'))
	{
		$self->{'id'} = $context->uri('#' . $element->getAttribute('id'));
	}
	else
	{
		$self->{'id'} = $context->make_bnode($element);
	}
	
	return undef unless $element->localname =~ /^[DOU]L$/i;
	$self->{'DATA'} = $self->_parse_list($element->cloneNode(1));

	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub _parse_list
{
	my ($self, $e) = @_;
	
	if (lc $e->localname eq 'ul')
		{ return HTML::Microformats::XOXO::UL->parse($e, $self); }
	elsif (lc $e->localname eq 'ol')
		{ return HTML::Microformats::XOXO::OL->parse($e, $self); }
	elsif (lc $e->localname eq 'dl')
		{ return HTML::Microformats::XOXO::DL->parse($e, $self); }
	
	return undef;
}

sub format_signature
{
	return {
		'root'         => 'xoxo',
		'classes'      => [],
		'options'      => {},
		'rdf:type'     => [] ,
		'rdf:property' => {},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1),
		RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
		RDF::Trine::Node::Resource->new('http://purl.org/dc/dcmitype/Dataset'),
		));

	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1),
		RDF::Trine::Node::Resource->new('http://open.vocab.org/terms/json'),
		$self->_make_literal( to_json($self, {canonical=>1,convert_blessed=>1}) ),
		));

	return $self;
}

sub profiles
{
	return qw(http://microformats.org/profile/xoxo
		http://ufs.org/x/xoxo
		http://microformats.org/profile/specs
		http://ufs.org/x/specs
		http://purl.org/uF/2008/03/);
}

1;

package HTML::Microformats::XOXO::DL;

use common::sense;
use 5.008;

use HTML::Microformats::_util qw(stringify xml_stringify);

sub parse
{
	my ($class, $e, $xoxo) = @_;
	my $dict;
	
	my $term;
	foreach my $kid ($e->childNodes)
	{
		next unless $kid->isa('XML::LibXML::Element');
		
		if ($kid->localname =~ /^DT$/i)
		{
			$term = stringify($kid);
		}
		elsif (defined $term)
		{
			push @{ $dict->{$term} }, HTML::Microformats::XOXO::DD->parse($kid, $xoxo);
		}
	}
	
	bless $dict, $class;
}

sub TO_JSON
{
	return { %{$_[0]} };
}

1;

package HTML::Microformats::XOXO::UL;

use common::sense;
use 5.008;

sub parse
{
	my ($class, $e, $xoxo) = @_;
	my @items;
	
	foreach my $li ($e->getChildrenByTagName('li'))
		{ push @items, HTML::Microformats::XOXO::LI->parse($li, $xoxo); }
	
	bless \@items, $class;
}

sub TO_JSON
{
	return [ @{$_[0]} ];
}

1;

package HTML::Microformats::XOXO::OL;

use base qw(HTML::Microformats::XOXO::UL);
use common::sense;
use 5.008;

1;

package HTML::Microformats::XOXO::LI;

use common::sense;
use 5.008;

use HTML::Microformats::_util qw(stringify xml_stringify);

our $for_get_them_not = 'a|dl|li|ol|ul';

sub parse
{
	my ($class, $e, $xoxo) = @_;
	my $self = bless {}, $class;
	
	my $a  = $self->_get_them($e, 'a');
	my $dl = $self->_get_them($e, 'dl');
	my $l  = $self->_get_them($e, 'ol|ul');
	
	if ($a)
	{
		$self->{'url'}   = $xoxo->context->uri($a->getAttribute('href'))
			if $a->hasAttribute('href');
		$self->{'type'}  = $a->getAttribute('type')
			if $a->hasAttribute('type');
		$self->{'rel'}   = $a->getAttribute('rel')
			if $a->hasAttribute('rel');
		$self->{'title'} = $a->getAttribute('title')
			if $a->hasAttribute('title');
	}
	
	if ($dl)
	{
		$self->{'properties'} = HTML::Microformats::XOXO::DL->parse($dl, $xoxo);
		$dl->parentNode->removeChild($dl);
	}

	if (defined $l && lc $l->localname eq 'ul')
	{
		$self->{'children'} = HTML::Microformats::XOXO::UL->parse($l, $xoxo);
		$l->parentNode->removeChild($l);
	}
	elsif (defined $l && lc $l->localname eq 'ol')
	{
		$self->{'children'} = HTML::Microformats::XOXO::OL->parse($l, $xoxo);
		$l->parentNode->removeChild($l);
	}
	
	$self->{'text'} = stringify($e);
	$self->{'html'} = xml_stringify($e);

	return $self;
}

sub _get_them
{
	my ($self, $e, $pattern) = @_;
	
	my @rv;
	my @check = $e->childNodes;
	
	while (@check)
	{
		my $elem = shift @check;
		next unless $elem->isa('XML::LibXML::Element');
		
		if ($elem->localname =~ /^($pattern)$/i)
		{
			if (wantarray)
				{ push @rv, $elem; }
			else
				{ return $elem; }
		}
		if ($elem->localname !~ /^($for_get_them_not)$/i)
		{
			unshift @check, $elem->childNodes;
		}
	}
	
	if (wantarray)
		{ return @rv; }
	else
		{ return undef; }
}

sub TO_JSON
{
	my %rv = %{$_[0]};
	delete $rv{'html'};
	return \%rv;
}

1;

package HTML::Microformats::XOXO::DD;

use base qw(HTML::Microformats::XOXO::LI);
use common::sense;
use 5.008;

1;
