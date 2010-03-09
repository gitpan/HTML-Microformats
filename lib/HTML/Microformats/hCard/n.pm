package HTML::Microformats::hCard::n;

use base qw(HTML::Microformats::BASE HTML::Microformats::Mixin::Parser);
use common::sense;
use 5.008;

use HTML::Microformats::hCard;

sub new
{
	my ($class, $element, $context) = @_;
	my $cache = $context->cache;
	
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
	
	return $self;
}

sub format_signature
{
	my $self  = shift;
	my $vcard = 'http://www.w3.org/2006/vcard/ns#';
	my $vx    = 'http://buzzword.org.uk/rdf/vcardx#';

	return {
		'root' => 'n',
		'classes' => [
			['additional-name',  '*'],
			['family-name',      '*'],
			['given-name',       '*'],
			['honorific-prefix', '*'],
			['honorific-suffix', '*'],
			['initial',          '*'], # extension
		],
		'options' => {
			'no-destroy' => ['adr', 'geo']
		},
		'rdf:type' => ["${vcard}Name"] ,
		'rdf:property' => {
			'additional-name'   => { 'literal' => ["${vcard}additional-name"] } ,
			'family-name'       => { 'literal' => ["${vcard}family-name"] } ,
			'given-name'        => { 'literal' => ["${vcard}given-name"] } ,
			'honorific-prefix'  => { 'literal' => ["${vcard}honorific-prefix"] } ,
			'honorific-suffix'  => { 'literal' => ["${vcard}honorific-suffix"] } ,
			'honorific-initial' => { 'literal' => ["${vx}initial"] } ,
		},
	};
}

sub profiles
{
	return HTML::Microformats::hCard::profiles(@_);
}

1;
