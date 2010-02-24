package HTML::Microformats::XFN;

use base qw(HTML::Microformats::_base);
use common::sense;
use 5.008;

use HTML::Microformats::_util qw(stringify searchAncestorClass);
use HTML::Microformats::hCard;
use RDF::Trine;

sub new
{
	my ($class, $element, $context) = @_;
	my $cache = $context->cache;
	
	return $cache->get($context, $element, $class)
		if defined $cache && $cache->get($context, $element, $class);
	
	my $self = bless {
		'element'    => $element ,
		'context'    => $context ,
		'cache'      => $cache ,
		}, $class;

	# Extract XFN-related @rel values.
	$self->_extract_xfn_relationships;
	
	# If none, then just return undef.
	return undef
		unless @{ $self->{'DATA'}->{'rel'} }
		||     @{ $self->{'DATA'}->{'rev'} };

	$self->{'DATA'}->{'href'}  = $context->uri( $element->getAttribute('href') );
	$self->{'DATA'}->{'label'} = stringify($element, 'value');
	$self->{'DATA'}->{'title'} = $element->hasAttribute('title')
	                           ? $element->getAttribute('title')
	                           : $self->{'DATA'}->{'label'};
										
	$self->{'id'}        = $self->{'DATA'}->{'href'};
	$self->{'id.person'} = $context->make_bnode;
	
	my $hcard_element = searchAncestorClass('vcard', $element, 0);
	if ($hcard_element)
	{
		$self->{'hcard'} = HTML::Microformats::hCard->new($hcard_element, $context);
		if ($self->{'hcard'})
		{
			$self->{'id.person'} = $self->{'hcard'}->id(0, 'holder');
		}
	}
	
	$self->context->representative_hcard;

	$cache->set($context, $element, $class, $self)
		if defined $cache;
		
	return $self;
}

sub extract_all
{
	my ($class, $dom, $context) = @_;

	my @links  = $dom->getElementsByTagName('link');
	push @links, $dom->getElementsByTagName('a');
	push @links, $dom->getElementsByTagName('area');
	
	my @rv;
	foreach my $link (@links)
	{
		my $xfn = $class->new($link, $context);
		push @rv, $xfn if defined $xfn;
	}
	
	return @rv;
}

sub _extract_xfn_relationships
{
	my ($self) = @_;
	
	my $R = $self->_xfn_relationship_types;
	
	my $regexp = join '|', keys %$R;
	$regexp = "\\b($regexp)\\b";

	foreach my $direction (qw(rel rev))
	{
		if ($self->{'element'}->hasAttribute($direction))
		{
			my @matches = ($self->{'element'}->getAttribute($direction) =~ /$regexp/gi);
			$self->{'DATA'}->{$direction} = \@matches if @matches;
		}
	}
}

sub add_to_model
{
	my ($self, $model) = @_;
	
	my $R = $self->_xfn_relationship_types;
	
	foreach my $r (@{ $self->data->{'rel'} })
	{
		next if $r =~ /^me$/i;

		my ($page_link, $person_link);
		
		if ($R->{$r} =~ /^[^:]*E/)
		{
			$page_link   = "http://buzzword.org.uk/rdf/xen#${r}-hyperlink";
			$person_link = "http://buzzword.org.uk/rdf/xen#${r}";
		}
		elsif ($R->{$r} =~ /^[^:]*R/)
		{
			$page_link   = "http://vocab.sindice.com/xfn#human-relationship-hyperlink";
			$person_link = "http://purl.org/vocab/relationship/${r}";
		}
		else
		{
			$page_link   = "http://vocab.sindice.com/xfn#${r}-hyperlink";
			$person_link = "http://vocab.sindice.com/xfn#${r}";
		}
		
		$model->add_statement(RDF::Trine::Statement->new(
			RDF::Trine::Node::Resource->new( $self->context->uri ),
			RDF::Trine::Node::Resource->new( $page_link ),
			RDF::Trine::Node::Resource->new( $self->data->{'href'} ),
			));

		$model->add_statement(RDF::Trine::Statement->new(
			$self->context->representative_person_id(1),
			RDF::Trine::Node::Resource->new( $person_link ),
			$self->id(1, 'person'),
			));
		
		if ($R->{$r} =~ /^[^:]*K/)
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->context->representative_person_id(1),
				RDF::Trine::Node::Resource->new( 'http://xmlns.com/foaf/0.1/knows' ),
				$self->id(1, 'person'),
				));
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'person'),
				RDF::Trine::Node::Resource->new( 'http://xmlns.com/foaf/0.1/knows' ),
				$self->context->representative_person_id(1),
				))
				if $R->{$r} =~ /^[^:]*S/;
		}
		
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, 'person'),
			RDF::Trine::Node::Resource->new( $person_link ),
			$self->context->representative_person_id(1),
			))
			if $R->{$r} =~ /^[^:]*S/;
		
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, 'person'),
			RDF::Trine::Node::Resource->new( $1 ),
			$self->context->representative_person_id(1),
			))
			if $R->{$r} =~ /^[^:]*I\:(.*)$/;
	}

	foreach my $r (@{ $self->data->{'rev'} })
	{
		next if $r =~ /^me$/i;
		
		my $person_link;
		
		if ($R->{$r} =~ /^[^:]*E/)
		{
			$person_link = "http://buzzword.org.uk/rdf/xen#${r}";
		}
		elsif ($R->{$r} =~ /^[^:]*R/)
		{
			$person_link = "http://purl.org/vocab/relationship/${r}";
		}
		else
		{
			$person_link = "http://vocab.sindice.com/xfn#${r}";
		}

		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, 'person'),
			RDF::Trine::Node::Resource->new( $person_link ),
			$self->context->representative_person_id(1),
			));

		if ($R->{$r} =~ /^[^:]*K/)
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'person'),
				RDF::Trine::Node::Resource->new( 'http://xmlns.com/foaf/0.1/knows' ),
				$self->context->representative_person_id(1),
				));
			$model->add_statement(RDF::Trine::Statement->new(
				$self->context->representative_person_id(1),
				RDF::Trine::Node::Resource->new( 'http://xmlns.com/foaf/0.1/knows' ),
				$self->id(1, 'person'),
				))
				if $R->{$r} =~ /^[^:]*S/;
		}
		
		$model->add_statement(RDF::Trine::Statement->new(
			$self->context->representative_person_id(1),
			RDF::Trine::Node::Resource->new( $person_link ),
			$self->id(1, 'person'),
			))
			if $R->{$r} =~ /^[^:]*S/;
		
		$model->add_statement(RDF::Trine::Statement->new(
			$self->context->representative_person_id(1),
			RDF::Trine::Node::Resource->new( $1 ),
			$self->id(1, 'person'),
			))
			if $R->{$r} =~ /^[^:]*I\:(.*)$/;
	}

	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1, 'person'),
		RDF::Trine::Node::Resource->new( 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' ),
		RDF::Trine::Node::Resource->new( 'http://xmlns.com/foaf/0.1/Person' ),
		));

	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1, 'person'),
		RDF::Trine::Node::Resource->new( 'http://xmlns.com/foaf/0.1/'.($self->data->{'href'} =~ /^mailto:/i ? 'mbox' : 'page') ),
		RDF::Trine::Node::Resource->new( $self->data->{'href'} ),
		));

	$model->add_statement(RDF::Trine::Statement->new(
		RDF::Trine::Node::Resource->new( $self->data->{'href'} ),
		RDF::Trine::Node::Resource->new( 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' ),
		RDF::Trine::Node::Resource->new( 'http://xmlns.com/foaf/0.1/Document' ),
		))
		unless $self->data->{'href'} =~ /^mailto:/i;
	
	if (grep /^me$/i, @{ $self->data->{'rel'} })
	{
		$model->add_statement(RDF::Trine::Statement->new(
			RDF::Trine::Node::Resource->new( $self->context->uri ),
			RDF::Trine::Node::Resource->new( 'http://vocab.sindice.com/xfn#mePage' ),
			RDF::Trine::Node::Resource->new( $self->data->{'href'} ),
			));
	}
	if (grep /^me$/i, @{ $self->data->{'rev'} })
	{
		$model->add_statement(RDF::Trine::Statement->new(
			RDF::Trine::Node::Resource->new( $self->data->{'href'} ),
			RDF::Trine::Node::Resource->new( 'http://vocab.sindice.com/xfn#mePage' ),
			RDF::Trine::Node::Resource->new( $self->context->uri ),
			));
	}	
}

sub profiles
{
	my $class = shift;
	return qw(http://gmpg.org/xfn/11
		http://purl.org/uF/2008/03/
		http://gmpg.org/xfn/1
		http://xen.adactio.com/
		http://purl.org/vocab/relationship/);
}


sub _xfn_relationship_types
{
	my ($self) = @_;
	
	my %xfn11 = (
		'contact'       => ':',
		'acquaintance'  => 'K:',
		'friend'        => 'K:',
		'met'           => 'SK:',
		'co-worker'     => 'S:',
		'colleague'     => 'S:',
		'co-resident'   => 'SKT:',
		'neighbor'      => 'S:',
		'child'         => 'I:http://vocab.sindice.com/xfn#parent',
		'parent'        => 'I:http://vocab.sindice.com/xfn#child',
		'sibling'       => 'S:',
		'spouse'        => 'SK:',
		'kin'           => 'S:',
		'muse'          => ':',
		'crush'         => 'K:',
		'date'          => 'SK:',
		'sweetheart'    => 'SK:',
		'me'            => 'S:',
	);
	
	my %R; # relationship types
	
	if ($self->context->has_profile('http://gmpg.org/xfn/11',
		'http://purl.org/uF/2008/03/'))
	{
		%R = %xfn11;
	}
	elsif ($self->context->has_profile('http://gmpg.org/xfn/1'))
	{
		%R = (
			'acquaintance'  => 'K:',
			'friend'        => 'K:',
			'met'           => 'SK:',
			'co-worker'     => 'S:',
			'colleague'     => 'S:',
			'co-resident'   => 'SKT:',
			'neighbor'      => 'S:',
			'child'         => 'I:http://vocab.sindice.com/xfn#parent',
			'parent'        => 'I:http://vocab.sindice.com/xfn#child',
			'sibling'       => 'S:',
			'spouse'        => 'SK:',
			'muse'          => ':',
			'crush'         => 'K:',
			'date'          => 'SK:',
			'sweetheart'    => 'SK:',
		);
	}

	if ($self->context->has_profile('http://xen.adactio.com/'))
	{
		$R{'nemesis'}    = 'SKE:';
		$R{'enemy'}      = 'KE:';
		$R{'nuisance'}   = 'KE:';
		$R{'evil-twin'}  = 'SE:';
		$R{'rival'}      = 'KE:';
		$R{'fury'}       = 'E:';
		$R{'creep'}      = 'E:';
	}

	if ($self->context->has_profile('http://purl.org/vocab/relationship/'))
	{
		$R{'acquaintanceOf'}    = 'KR:';
		$R{'ambivalentOf'}      = 'R:';
		$R{'ancestorOf'}        = 'RI:http://purl.org/vocab/relationship/descendantOf';
		$R{'antagonistOf'}      = 'KR:';
		$R{'apprenticeTo'}      = 'KR:';
		$R{'childOf'}           = 'KRI:http://purl.org/vocab/relationship/parentOf';
		$R{'closeFriendOf'}     = 'KR:';
		$R{'collaboratesWith'}  = 'SKR:';
		$R{'colleagueOf'}       = 'SKR:';
		$R{'descendantOf'}      = 'RI:http://purl.org/vocab/relationship/ancestorOf';
		$R{'employedBy'}        = 'KRI:http://purl.org/vocab/relationship/employerOf';
		$R{'employerOf'}        = 'KRI:http://purl.org/vocab/relationship/employedBy';
		$R{'enemyOf'}           = 'KR:';
		$R{'engagedTo'}         = 'SKR:';
		$R{'friendOf'}          = 'KR:';
		$R{'grandchildOf'}      = 'KRI:http://purl.org/vocab/relationship/grandparentOf';
		$R{'grandparentOf'}     = 'KRI:http://purl.org/vocab/relationship/grandchildOf';
		$R{'hasMet'}            = 'SKR:';
		$R{'influencedBy'}      = 'R:';
		$R{'knowsByReputation'} = 'R:';
		$R{'knowsInPassing'}    = 'KR:';
		$R{'knowsOf'}           = 'R:';
		$R{'lifePartnerOf'}     = 'SKR:';
		$R{'livesWith'}         = 'SKR:';
		$R{'lostContactWith'}   = 'KR:';
		$R{'mentorOf'}          = 'KR:';
		$R{'neighborOf'}        = 'SKR:';
		$R{'parentOf'}          = 'KRI:http://purl.org/vocab/relationship/childOf';
		$R{'siblingOf'}         = 'SKR:';
		$R{'spouseOf'}          = 'SKR:';
		$R{'worksWith'}         = 'SKR:';
		$R{'wouldLikeToKnow'}   = 'R:';
	}
	
	return \%R if %R;
	
	return \%xfn11;
}


1;