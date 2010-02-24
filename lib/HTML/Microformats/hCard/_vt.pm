package HTML::Microformats::hCard::_vt;

# _vt = value+type structures.

use base qw(HTML::Microformats::_base HTML::Microformats::_simple_parser);
use common::sense;
use 5.008;

use HTML::Microformats::hCard;
use HTML::Microformats::_util qw(searchClass stringify);

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

	my $hclass = 'tel';
	$hclass = $1 if $class =~ /::([^:]+)$/;

	my $clone = $element->cloneNode(1);	
	$self->_expand_patterns($clone);
	$self->_simple_parse($clone);
	
	unless (length $self->{'DATA'}->{'value'} or $hclass eq 'label')
	{
		if ($element->hasAttribute('href'))
		{
			$self->{'DATA'}->{'value'} = $self->context->uri( $element->getAttribute('href') );
		}
		elsif ($element->hasAttribute('src'))
		{
			$self->{'DATA'}->{'value'} = $self->context->uri( $element->getAttribute('src') );
		}
	}
	unless (length $self->{'DATA'}->{'value'})
	{
		my @types = searchClass('type', $clone);
		foreach my $type (@types)
		{
			$type->parentNode->removeChild($type);
		}
		$self->{'DATA'}->{'value'} = stringify($clone);
		$self->{'DATA'}->{'value'} =~ s/(^\s+|\s+$)//g;
	}

	return $self;
}

sub format_signature
{
	my $self  = shift;
	my $vcard = 'http://www.w3.org/2006/vcard/ns#';
	my $vx    = 'http://buzzword.org.uk/rdf/vcardx#';
	
	my $package = $self;
	$package = ref $package if ref $package;
	
	my $hclass = 'tel';
	$hclass = $1 if $package =~ /::([^:]+)$/;

	return {
		'root' => $hclass,
		'classes' => [
			['type',  '*'],
			['value', '&v'],
		],
		'options' => {
			'no-destroy' => ['adr', 'geo']
		},
		'rdf:type' => [ (($hclass =~ /^(tel|email|label)$/) ? $vcard : $vx).ucfirst $hclass ] ,
		'rdf:property' => {
			'type'  => { 'literal' => ["${vx}usage"] } ,
			'value' => { 'literal' => ["http://www.w3.org/1999/02/22-rdf-syntax-ns#value"] , 'resource' => ["http://www.w3.org/1999/02/22-rdf-syntax-ns#value"] } ,
		},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);
	
	my @types;
	foreach my $type (@{ $self->data->{'type'} })
	{
		if ($type =~ /^(dom|home|intl|parcel|postal|pref|work|video|x400|voice|PCS|pager|msg|modem|ISDN|internet|fax|cell|car|BBS)$/i)
		{
			my $canon = ucfirst lc $1;
			$canon = uc $canon if $canon=~ /(pcs|bbs|isdn)/i;
			
			push @types, {
					'value' => 'http://www.w3.org/2006/vcard/ns#'.$canon,
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
	
	return $self;
}

sub profiles
{
	return HTML::Microformats::hCard::profiles(@_);
}

1;
