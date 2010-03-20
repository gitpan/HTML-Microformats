package HTML::Microformats::hReview::rating;

use base qw(HTML::Microformats::BASE HTML::Microformats::Mixin::Parser);
use common::sense;
use 5.008;

use HTML::Microformats::_util qw(stringify searchClass);
use XML::LibXML qw(:libxml);

sub new
{
	my ($class, $element, $context, %options) = @_;
	my $cache = $context->cache;
	
	return $cache->get($context, $element, $class)
		if defined $cache && $cache->get($context, $element, $class);

	my $self = {
		'element'    => $element ,
		'context'    => $context ,
		'cache'      => $cache ,
		'id'         => $context->make_bnode($element) ,
		'id.holder'  => $context->make_bnode ,
		};
	
	bless $self, $class;
	
	# Find value - that's the easy part.
	$self->{'DATA'}->{'value'} = stringify($element, 'value');
	
	# If element is a descendent of something with rel=tag,
	# then ascend the tree to find that.
	my $parent = $element;
	while (defined $parent && ref $parent && $parent->nodeType == XML_ELEMENT_NODE)
	{
		last if $parent->getAttribute('rel') =~ /\b(tag)\b/i;
		$parent = $parent->parentNode;
	}
	$parent = undef
		unless $parent->nodeType == XML_ELEMENT_NODE 
		&&     $parent->getAttribute('rel') =~ /\b(tag)\b/i;
	
	# Search for class=best|worst within $element,
	# or in higher rel=tag element.
	my $root_node = $parent || $element;
	foreach my $limit (qw(best worst))
	{
		my @elems = searchClass($limit, $root_node);
		$self->{'DATA'}->{$limit} = stringify($elems[0], {'abbr-pattern'=>1});
	}
	
	# Default them to 0.0 and 5.0.
	$self->{'DATA'}->{'worst'} = '0.0'
		unless defined $self->{'DATA'}->{'worst'};
	$self->{'DATA'}->{'best'} = '5.0'
		unless defined $self->{'DATA'}->{'best'};

	if ($parent) # only defined if $element has a rel=tag ancestor
	{
		$self->{'DATA'}->{'tag'} =
			[ HTML::Microformats::RelTag->new($parent, $context) ];
	}
	else
	{
		$self->{'DATA'}->{'tag'} =
			[ HTML::Microformats::RelTag->extract_all($element, $context) ];
	}

	$cache->set($context, $element, $class, $self)
		if defined $cache;
	
	return $self;
}

sub format_signature
{
	my $self  = shift;
	
	my $rev     = 'http://www.purl.org/stuff/rev#';
	my $hreview = 'http://ontologi.es/hreview#';

	my $rv = {
		'root'    => 'rating',
		'classes' => [
			['value', 'n?v#'],
			['best',  'n?v#'],
			['worst', 'n?v#'],
		],
		'options' => {
			'rel-tag'     => 'tag',
		},
		'rdf:type' => ["${hreview}Rating"] ,
		'rdf:property' => {
			'value'  => { 'literal'  => ["http://www.w3.org/1999/02/22-rdf-syntax-ns#value"] , 'literal_datatype' => 'decimal' },
			'best'   => { 'literal'  => ["${hreview}best"] , 'literal_datatype' => 'decimal' },
			'worst'  => { 'literal'  => ["${hreview}worst"] , 'literal_datatype' => 'decimal' },
			'tag'    => { 'resource' => ["${hreview}rated-on"] },
		},
	};
		
	return $rv;
}

1;