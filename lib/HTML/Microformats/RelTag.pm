package HTML::Microformats::RelTag;

use base qw(HTML::Microformats::_base);
use common::sense;
use 5.008;

use CGI::Util qw(unescape);
use HTML::Microformats::Datatypes::String qw(ms);
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
	my $tag = $self->{'DATA'}->{'href'};
	$tag =~ s/\#.*$//;
	$tag =~ s/\?.*$//;
	$tag =~ s/\/$//;
	if ($tag =~ m{^(.*/)([^/]+)$})
	{
		$self->{'DATA'}->{'tagspace'} = $1;
		$self->{'DATA'}->{'tag'}      = ms(unescape($2), $element);
	}
	$self->{'DATA'}->{'label'}   = stringify($element, 'value');
	$self->{'DATA'}->{'label'} ||= $self->{'DATA'}->{'tag'};
	$self->{'DATA'}->{'title'}   = $element->hasAttribute('title')
	                             ? $element->getAttribute('title')
	                             : $self->{'DATA'}->{'label'};
	
	$cache->set($context, $element, $class, $self)
		if defined $cache;
	
	return $self;
}

sub format_signature
{
	my $t    = 'http://www.holygoat.co.uk/owl/redwood/0.1/tags/';
	my $awol = 'http://bblfish.net/work/atom-owl/2006-06-06/#';
	
	return {
		'rel'      => 'tag' ,
		'classes'  => [
				['tag',      '1#'] ,
				['tagspace', '1#'] ,
				['href',     '1#'] ,
				['label',    '1#'] ,
				['title',    '1#'] ,
			] ,
		'rdf:type' => ["${t}Tag","${awol}Category"] ,
		'rdf:property' => {
			'tag'      => { 'literal'  => ["${awol}term", "${t}name", "http://www.w3.org/2000/01/rdf-schema#label"] },
			'tagspace' => { 'resource' => ["${awol}scheme"] },
			'href'     => { 'resource' => ["http://xmlns.com/foaf/0.1/page"] },
			} ,
		}
}

sub profiles
{
	my $class = shift;
	return qw(http://microformats.org/profile/rel-tag
		http://ufs.cc/x/rel-tag
		http://purl.org/uF/rel-tag/1.0/
		http://purl.org/uF/2008/03/);
}

1;