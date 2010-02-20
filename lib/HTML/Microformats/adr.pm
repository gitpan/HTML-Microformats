package HTML::Microformats::adr;

use base qw(HTML::Microformats::_base HTML::Microformats::_simple_parser);
use common::sense;
use 5.008;

use Locale::Country qw(country2code LOCALE_CODE_ALPHA_2);

sub new
{
	# HTML::Microformats::adr->new($html_element, $context, [$cache]);

	my ($class, $element, $context, $cache) = @_;
	
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
	my $vcard = 'http://www.w3.org/2006/vcard/ns#';
	my $geo   = 'http://www.w3.org/2003/01/geo/wgs84_pos#';

	return {
		'root' => 'adr',
		'classes' => [
			['geo',              'm*', {'embedded'=>'geo'}], # extension to the spec
			['post-office-box',  '*'],
			['extended-address', '*'],
			['street-address',   '*'],
			['locality',         '*'],
			['region',           '*'],
			['postal-code',      '*'],
			['country-name',     '*'],
			['type',             '*']  # only allowed when used in hCard. still...
		],
		'options' => {
			'no-destroy' => ['geo']
		},
		'rdf:type' => ["${vcard}Address", "${geo}SpatialThing"] ,
		'rdf:property' => {
			'geo'              => { 'resource' => ["${geo}location"] } ,
			'post-office-box'  => { 'literal'  => ["${vcard}post-office-box"] } ,
			'extended-address' => { 'literal'  => ["${vcard}extended-address"] } ,
			'locality'         => { 'literal'  => ["${vcard}locality"] } ,
			'region'           => { 'literal'  => ["${vcard}region"] } ,
			'postal-code'      => { 'literal'  => ["${vcard}postal-code"] } ,
			'country-name'     => { 'literal'  => ["${vcard}country-name"] } ,
		},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);

	# Map 'type' (only for valid hCard types though)
	my @types;
	foreach my $type (@{ $self->data->{'type'} })
	{
		if ($type =~ /^(dom|home|intl|parcel|postal|pref|work)$/i)
		{
			push @types, {
					'value' => 'http://www.w3.org/2006/vcard/ns#'.(ucfirst lc $1),
					'type'  => 'uri',
				};
		}
	}
	if (@types)
	{
		$model->add_hashref({
			$self->id =>
				{ 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => \@types }
			});
	}
	
	# Some clever additional stuff: figure out what country code they meant!
	foreach my $country (@{ $self->data->{'country-name'} })
	{
		my $code = country2code($country, LOCALE_CODE_ALPHA_2);
		if (defined $code)
		{
			$model->add_hashref({
				$self->id =>
					{ 'http://www.geonames.org/ontology#inCountry' => [{ 'type'=>'uri', 'value'=>'http://ontologi.es/place/'.(uc $code) }] }
				});
		}
	}

	return $self;
}

sub profiles
{
	my $class = shift;
	return qw(http://purl.org/uF/adr/0.9/
		http://microformats.org/profile/hcard
		http://ufs.cc/x/hcard
		http://www.w3.org/2006/03/hcard
		http://purl.org/uF/hCard/1.0/
		http://purl.org/uF/2008/03/ );
}

1;
