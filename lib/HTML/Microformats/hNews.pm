package HTML::Microformats::hNews;

use base qw(HTML::Microformats::hEntry);
use common::sense;
use 5.008;

use HTML::Microformats::_util qw(searchClass);
use HTML::Microformats::hCard;

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
	
	my $clone = $self->_hentry_parse;
	
	# hNews has a source-org which is probably an hCard.
	$self->_source_org_fallback($clone);

	$self->{'DATA'}->{'class'} = 'hnews';
	
	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub _source_org_fallback
{
	my ($self, $clone) = @_;
	
	unless (@{ $self->{'DATA'}->{'source-org'} })
	{
		##TODO: Should really only use the nearest-in-parent
		my @so_elements = searchClass('source-org', $self->context->document->documentElement);
		foreach my $so (@so_elements)
		{
			next unless $so->getAttribute('class') =~ /\b(vcard)\b/;
			
			push @{ $self->{'DATA'}->{'source-org'} }, HTML::Microformats::hCard->new($so, $self->context);
		}
	}
}

sub format_signature
{
	my $rv   = HTML::Microformats::hEntry->format_signature;
	
	$rv->{'root'} = 'hnews';
	
	push @{ $rv->{'classes'} }, (
		['source-org',   'm?',  {embedded=>'hCard'}],
		['dateline',     'M?',  {embedded=>'hCard adr'}],
		['geo',          'm*',  {embedded=>'geo'}],
		['item-license', 'ur*'],
		['principles',   'ur*'],
		);
	
	my $hnews = 'http://ontologi.es/hnews#';
	my $iana  = 'http://www.iana.org/assignments/relation/';
	
	$rv->{'rdf:property'}->{'source-org'}->{'resource'}   = ["${hnews}source-org"];
	$rv->{'rdf:property'}->{'dateline'}->{'resource'}     = ["${hnews}dateline"];
	$rv->{'rdf:property'}->{'dateline'}->{'literal'}      = ["${hnews}dateline-literal"];
	$rv->{'rdf:property'}->{'geo'}->{'resource'}          = ["${hnews}geo"];
	$rv->{'rdf:property'}->{'item-license'}->{'resource'} = ["${iana}license", "http://creativecommons.org/ns#license"];
	$rv->{'rdf:property'}->{'principles'}->{'resource'}   = ["${hnews}principles"];
	
	return $rv;
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->SUPER::add_to_model($model);
	
	return $self;
}

sub profiles
{
	my $class = shift;
	return qw(http://purl.org/uF/hNews/0.1/);
}


1;
