package HTML::Microformats::geo;

use base qw(HTML::Microformats::_base HTML::Microformats::_simple_parser);
use common::sense;
use 5.008;

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

	if (!defined($self->{'DATA'}->{'longitude'}) || !defined($self->{'DATA'}->{'latitude'}))
	{
		my $str = $clone->toString;
		$str = $clone->getAttribute('alt')
			if $clone->localname eq 'img' || $clone->localname eq 'area';

		if ($str =~ / \s* \+?(\-?[0-9\.]+) \s* [\,\;] \s* \+?(\-?[0-9\.]+) \s* /x)
		{
			$self->{'DATA'}->{'latitude'}  = $1;
			$self->{'DATA'}->{'longitude'} = $2;
		}
	}
	
	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub format_signature
{
	my $vcard = 'http://www.w3.org/2006/vcard/ns#';
	my $geo   = 'http://www.w3.org/2003/01/geo/wgs84_pos#';

	return {
		'root' => 'geo',
		'classes' => [
			['longitude',        'n?'],
			['latitude',         'n?'],
			['body',             '?'], # extension
			['reference-frame',  '?'], # extension
			['altitude',         'M?', {embedded=>'hMeasure'}] # extension
		],
		'options' => {
		},
		'rdf:type' => ["${vcard}Location", "${geo}Point"] ,
		'rdf:property' => {
			'latitude'         => { 'literal'  => ["${vcard}latitude", "${geo}lat"] } ,
			'longitude'        => { 'literal'  => ["${vcard}longitude", "${geo}long"] } ,
			'altitude'         => { 'literal'  => ["${geo}alt"] } ,
		},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	if (defined $self->data->{'body'}
	or (defined $self->data->{'reference-frame'} && $self->data->{'reference-frame'}!~ /wgs[-\s]?84/i))
	{
		my $rdf = {
				$self->id =>
				{
					'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' =>
						[{ 'value'=>'http://buzzword.org.uk/rdf/ungeo#Point' , 'type'=>'uri' }]
				}
			};
		foreach my $p (qw(altitude longitude latitude))
		{
			if (defined $self->data->{$p})
			{
				$rdf->{$self->id}->{'http://buzzword.org.uk/rdf/ungeo#'.$p} =
					[{ 'value'=>$self->data->{$p}, 'type'=>'literal' }];
			}
		}
		$self->{'rdf:resource'}->{'system'} = $self->context->make_bnode
			unless defined $self->{'rdf:resource'}->{'system'};
		
		$rdf->{$self->id}->{'http://buzzword.org.uk/rdf/ungeo#system'} =
			[{ 'value'=>$self->{'rdf:resource'}->{'system'}, 'type'=>'bnode' }];
		$rdf->{$self->{'rdf:resource'}->{'system'}}->{'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'} =
			[{ 'value'=>'http://buzzword.org.uk/rdf/ungeo#ReferenceSystem', 'type'=>'uri' }];
		$rdf->{$self->{'rdf:resource'}->{'system'}}->{'http://www.w3.org/2000/01/rdf-schema#label'} =
			[{ 'value'=>$self->data->{'reference-frame'}, 'type'=>'literal' }]
			if defined $self->data->{'reference-frame'};
		$rdf->{$self->{'rdf:resource'}->{'system'}}->{'http://buzzword.org.uk/rdf/ungeo#body'} =
			[{ 'value'=>$self->data->{'body'}, 'type'=>'literal' }]
			if defined $self->data->{'body'};
		
		$model->add_hashref($rdf);
	}
	else
	{
		$self->_simple_rdf($model);
	}

	return $self;
}

sub profiles
{
	my $class = shift;
	return qw(http://purl.org/uF/geo/0.9/
		http://microformats.org/profile/hcard
		http://ufs.cc/x/hcard
		http://www.w3.org/2006/03/hcard
		http://purl.org/uF/hCard/1.0/
		http://purl.org/uF/2008/03/ );
}

1;
