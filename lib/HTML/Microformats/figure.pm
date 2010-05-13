=head1 NAME

HTML::Microformats::figure - the figure microformat

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

HTML::Microformats::figure inherits from HTML::Microformats::BASE. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::figure;

use base qw(HTML::Microformats::BASE HTML::Microformats::Mixin::Parser);
use common::sense;
use 5.008;

use HTML::Microformats::_util qw(searchClass searchID stringify);
use HTML::Microformats::Datatypes::String qw(ms);
use Locale::Country qw(country2code LOCALE_CODE_ALPHA_2);

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
	
	my $clone = $element->cloneNode(1);	
	$self->_expand_patterns($clone);
	$self->_figure_parse($clone);
	
	if (defined $self->{'DATA'}->{'image'})
	{
		$self->{'id'} = $self->{'DATA'}->{'image'};
	}
	else
	{
		return undef;
	}

	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub _figure_parse
{
	my ($self, $elem) = @_;
	
	my ($desc_node, $image_node);
	
	if ($elem->localname eq 'img' && $elem->getAttribute('class')=~/\b(image)\b/)
	{
		$image_node = $elem;
	}
	else
	{
		my @images = searchClass('image', $elem);
		@images = $elem->getElementsByTagName('img') unless @images;
		$image_node = $images[0] if @images;
	}
	
	if ($elem->localname eq 'img')
	{
		$image_node ||= $elem;
	}
	
	if ($image_node)
	{
		$self->{'DATA'}->{'image'} = $self->context->uri($image_node->getAttribute('src'));
		$self->{'DATA'}->{'alt'}   = ms($image_node->getAttribute('alt'), $image_node)
			if $image_node->hasAttribute('alt');
		$self->{'DATA'}->{'title'} = ms($image_node->getAttribute('title'), $image_node)
			if $image_node->hasAttribute('title');
		
		if ($image_node->getAttribute('longdesc') =~ m'^#(.+)$')
		{
			$desc_node = searchID($1, $self->context->dom->documentElement);
			
			my $dnp = $desc_node->getAttribute('data-cpan-html-microformats-nodepath');
			my $rnp = $elem->getAttribute('data-cpan-html-microformats-nodepath');
			unless ($rnp eq substr $dnp, 0, length $rnp)
			{
				$elem->addChild($desc_node->clone(1));
			}
		}
	}
	
	# Just does class=credit, class=subject and rel=tag.
	$self->_simple_parse($elem);
	
	my @legends;
	push @legends, $elem if $elem->getAttribute('class')=~/\b(legend)\b/;
	push @legends, searchClass('legend', $elem);
	foreach my $l ($elem->getElementsByTagName('legend'))
	{
		push @legends, $l
			unless $l->getAttribute('class')=~/\b(legend)\b/; # avoid duplicates
	}
	
	foreach my $legend_node (@legends)
	{
		my $legend;
		if ($legend_node == $image_node)
		{
			$legend = ms($legend_node->getAttribute('title'), $legend_node)
				if $legend_node->hasAttribute('title');
		}
		else
		{
			$legend = stringify($legend_node, 'value');
		}
		
		push @{ $self->{'DATA'}->{'legend'} }, $legend if defined $legend;
	}
}

sub extract_all
{
	my ($class, $dom, $context, %options) = @_;
	my @rv;

	my @elements = searchClass('figure', $dom);
	foreach my $f ($dom->getElementsByTagName('figure'))
	{
		push @elements, $f
			unless $f->getAttribute('class')=~/\b(figure)\b/;
	}
	
	foreach my $e (@elements)
	{
		my $object = $class->new($e, $context, %options);
		next unless $object;
		next if grep { $_->id eq $object->id } @rv; # avoid duplicates
		push @rv, $object if ref $object;
	}
		
	return @rv;
}

sub format_signature
{
	my $vcard = 'http://www.w3.org/2006/vcard/ns#';
	my $geo   = 'http://www.w3.org/2003/01/geo/wgs84_pos#';
	my $foaf  = 'http://xmlns.com/foaf/0.1/';

	return {
		'root' => 'figure',
		'classes' => [
			['image',            '1u#'],
			['legend',           '+#'],
			['credit',           'M*', {embedded=>'hCard'}],
			['subject',          'M*', {embedded=>'hCard adr geo hEvent'}],
		],
		'options' => {
			'rel-tag' => 'category',
		},
		'rdf:type' => ["${foaf}Image"] ,
		'rdf:property' => {
			'legend'   => { literal  => ['http://purl.org/dc/terms/description'] },
			'category' => { resource => ['http://www.holygoat.co.uk/owl/redwood/0.1/tags/taggedWithTag'] },
		},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);
	
	foreach my $subject (@{ $self->{'DATA'}->{'subject'} })
	{
		if (UNIVERSAL::isa($subject, 'HTML::Microformats::hCard'))
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/depicts'),
				$subject->id(1, 'holder'),
				));
		}

		elsif (UNIVERSAL::isa($subject, 'HTML::Microformats::adr'))
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/depicts'),
				$subject->id(1, 'place'),
				));
		}

		elsif (UNIVERSAL::isa($subject, 'HTML::Microformats::geo'))
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/depicts'),
				$subject->id(1, 'location'),
				));
		}

		elsif (UNIVERSAL::isa($subject, 'HTML::Microformats::hEvent'))
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/depicts'),
				$subject->id(1, 'event'),
				));
		}

		# TODO: handle plain text
	}

	foreach my $credit (@{ $self->{'DATA'}->{'credit'} })
	{
		if (UNIVERSAL::isa($credit, 'HTML::Microformats::hCard'))
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new('http://purl.org/dc/terms/contributor'),
				$credit->id(1, 'holder'),
				));
		}

		# TODO: handle plain text
	}

	return $self;
}

sub profiles
{
	my $class = shift;
	return qw(http://purl.org/uF/figure/draft);
}

1;

=head1 MICROFORMAT

HTML::Microformats::figure supports figure as described at
L<http://microformats.org/wiki/figure>.

=head1 RDF OUTPUT

Data is returned using Dublin Core and FOAF.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::BASE>,
L<HTML::Microformats>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

