package HTML::Microformats::hCard::org;

use base qw(HTML::Microformats::_base HTML::Microformats::_simple_parser);
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
		'root' => 'org',
		'classes' => [
			['organization-name',   '?'],
			['organization-unit',   '*'],
			['x-vat-number',        '?'],
			['x-charity-number',    '?'],
			['x-company-number',    '?'],
			['vat-number',          '?', {'use-key'=>'x-vat-number'}],
			['charity-number',      '?', {'use-key'=>'x-charity-number'}],
			['company-number',      '?', {'use-key'=>'x-company-number'}],
		],
		'options' => {
			'no-destroy' => ['adr', 'geo']
		},
		'rdf:type' => ["${vcard}Organization"] ,
		'rdf:property' => {
			'organization-name'   => { 'literal' => ["${vcard}organization-name"] } ,
			'organization-unit'   => { 'literal' => ["${vcard}organization-unit"] } ,
			'x-vat-number'        => { 'literal' => ["${vx}x-vat-number"] } ,
			'x-charity-number'    => { 'literal' => ["${vx}x-charity-number"] } ,
			'x-company-number'    => { 'literal' => ["${vx}x-company-number"] } ,
		},
	};
}

sub profiles
{
	return HTML::Microformats::hCard::profiles(@_);
}

1;
