package HTML::Microformats::RELBASE;

use base qw(HTML::Microformats::BASE);
use common::sense;
use 5.008;

use HTML::Microformats::_util qw(stringify);

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
	
	$self->{'DATA'}->{'href'} = $context->uri( $element->getAttribute('href') );
	$self->{'DATA'}->{'label'}   = stringify($element, 'value');
	$self->{'DATA'}->{'title'}   = $element->hasAttribute('title')
	                             ? $element->getAttribute('title')
	                             : $self->{'DATA'}->{'label'};
	
	$cache->set($context, $element, $class, $self)
		if defined $cache;
	
	return $self;
}

1;