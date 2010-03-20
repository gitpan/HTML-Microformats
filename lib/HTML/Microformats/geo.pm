=head1 NAME

HTML::Microformats::geo - the geo microformat

=head1 SYNOPSIS

 use Data::Dumper;
 use HTML::Microformats::_context;
 use HTML::Microformats::geo;

 my $context = HTML::Microformats::_context->new($dom, $uri);
 my @geos    = HTML::Microformats::geo->extract_all(
                   $dom->documentElement, $context);
 foreach my $geo (@geos)
 {
   printf("%s;%s\n", $geo->get_latitude, $geo->get_longitude);
 }

=head1 DESCRIPTION

HTML::Microformats::geo inherits from HTML::Microformats::BASE. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::geo;

use base qw(HTML::Microformats::BASE HTML::Microformats::Mixin::Parser);
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
	
	my $clone = $element->cloneNode(1);	
	$self->_expand_patterns($clone);
	$self->_simple_parse($clone);

	if (!defined($self->{'DATA'}->{'longitude'}) || !defined($self->{'DATA'}->{'latitude'}))
	{
		my $str = stringify($clone, {
			'excerpt-class' => 'value',
			'value-title'   => 'allow',
			'abbr-pattern'   => 1,
			});
		
		if ($str =~ / ^\s* \+?(\-?[0-9\.]+) \s* [\,\;] \s* \+?(\-?[0-9\.]+) \s*$ /x)
		{
			$self->{'DATA'}->{'latitude'}  = $1;
			$self->{'DATA'}->{'longitude'} = $2;
		}

		# Last ditch attempt!!
		elsif ($clone->toString =~ / \s* \+?(\-?[0-9\.]+) \s* [\,\;] \s* \+?(\-?[0-9\.]+) \s* /x)
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
			['longitude',        'n?', {'value-title'=>'allow'}],
			['latitude',         'n?', {'value-title'=>'allow'}],
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

=head1 MICROFORMAT

HTML::Microformats::geo supports geo as described at
L<http://microformats.org/wiki/geo>, with the following additions:

=over 4

=item * 'altitude' property

You may provide an altitude as either a number (taken to be metres above sea level)
or an embedded hMeasure. e.g.:

 <span class="geo">
  lat:  <span class="latitude">12.34</span>,
  long: <span class="longitude">56.78</span>,
  alt:  <span class="altitude">90</span> metres.
 </span>
 
 <span class="geo">
  lat:  <span class="latitude">12.34</span>,
  long: <span class="longitude">56.78</span>,
  alt:  <span class="altitude hmeasure">
          <span class="num">90</span>
          <span class="unit">m</span>
        </span>.
 </span>

=item * 'body' and 'reference-frame'

The geo microformat is normally only defined for WGS84 co-ordinates on
Earth. Using 'body' and 'reference-frame' properties (each of which take
string values), you may give co-ordinates on other planets, asteroids,
moons, etc; or on Earth but using a non-WGS84 system.

=back

=head1 RDF OUTPUT

Data is returned using the W3C's vCard vocabulary
(L<http://www.w3.org/2006/vcard/ns#>) and the W3C's 
WGS84 vocabulary (L<http://www.w3.org/2003/01/geo/wgs84_pos#>).

For non-WGS84 co-ordinates, UNGEO (L<http://buzzword.org.uk/rdf/ungeo#>)
is used instead.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::BASE>,
L<HTML::Microformats>,
L<HTML::Microformats::hCard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
