=head1 NAME

HTML::Microformats::hCard - the hCard microformat

=head1 SYNOPSIS

 use HTML::Microformats::_context;
 use HTML::Microformats::hCard;

 my $context = HTML::Microformats::_context->new($dom, $uri);
 my @cards   = HTML::Microformats::hCard->extract_all(
                   $dom->documentElement, $context);
 foreach my $card (@cards)
 {
   print $card->get_fn . "\n";
 }

=head1 DESCRIPTION

HTML::Microformats::hCard inherits from HTML::Microformats::_base. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::hCard;

use base qw(HTML::Microformats::_base HTML::Microformats::_simple_parser);
use common::sense;
use 5.008;

use HTML::Microformats::Datatypes::String;
use HTML::Microformats::hCard::n;
use HTML::Microformats::hCard::org;
use HTML::Microformats::hCard::tel;
use HTML::Microformats::hCard::email;
use HTML::Microformats::hCard::label;
use HTML::Microformats::hCard::impp;

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
		'id.holder'  => $context->make_bnode ,
		};
	
	##TODO - detect if we're inside an hCalendar component.
	$self->{'in_hcalendar'} = 0;
	
	bless $self, $class;
	
	my $clone = $element->cloneNode(1);	
	$self->_expand_patterns($clone);
	$self->_simple_parse($clone);
	
	# In hCalendar, 'cn' is used instead of 'fn'.
	if ($self->{'in_hcalendar'})
	{
		$self->{'DATA'}->{'fn'} = $self->{'DATA'}->{'cn'}
			if  defined $self->{'DATA'}->{'cn'}
			&& !defined $self->{'DATA'}->{'fn'};
	}
	
	# Find more complicated nested structures.
	# These can't be handled by _simple_parse.
	push @{ $self->{'DATA'}->{'n'} },     HTML::Microformats::hCard::n->extract_all($clone, $context);
	push @{ $self->{'DATA'}->{'org'} },   HTML::Microformats::hCard::org->extract_all($clone, $context);
	push @{ $self->{'DATA'}->{'tel'} },   HTML::Microformats::hCard::tel->extract_all($clone, $context);
	push @{ $self->{'DATA'}->{'email'} }, HTML::Microformats::hCard::email->extract_all($clone, $context);
	push @{ $self->{'DATA'}->{'impp'} },  HTML::Microformats::hCard::impp->extract_all($clone, $context);
	push @{ $self->{'DATA'}->{'label'} }, HTML::Microformats::hCard::label->extract_all($clone, $context);	
	
	foreach my $p (qw(n org tel email impp label adr))
	{
		delete $self->{'DATA'}->{$p}
			unless @{ $self->{'DATA'}->{$p} };
	}
	
	# Fallback if no 'org' is found.
	# Try looking directly for org-like properties in the hCard.
	unless (defined $self->{'DATA'}->{'org'} and @{ $self->{'DATA'}->{'org'} })
	{
		my $org = HTML::Microformats::hCard::org->new($element, $context);
		$org->{'id'} = $context->make_bnode; # don't share ID with $self!!
		
		if ($org->data->{'organization-name'} || $org->data->{'organization-unit'})
		{
			push @{ $self->{'DATA'}->{'org'} }, $org;
		}
	}

	# Fallback if no 'n' is found.
	# Try looking directly for N-like properties in the hCard.
	unless (defined $self->{'DATA'}->{'n'} and @{ $self->{'DATA'}->{'n'} })
	{
		my $n = HTML::Microformats::hCard::n->new($element, $context);
		$n->{'id'} = $context->make_bnode; # don't share ID with $self!!
		
		if (@{ $n->data->{'family-name'} }
		||  @{ $n->data->{'given-name'} }
		||  @{ $n->data->{'additional-name'} }
		||  @{ $n->data->{'initial'} }
		||  @{ $n->data->{'honorific-prefix'} }
		||  @{ $n->data->{'honorific-suffix'} })
		{
			push @{ $self->{'DATA'}->{'n'} }, $n;
		}
	}
	
	# Detect kind ('individual', 'org', etc)
	$self->_detect_kind;
	
	# Perform N-optimisation.
	$self->_n_optimisation
		if lc $self->data->{'kind'} eq 'individual';

	$cache->set($context, $element, $class, $self)
		if defined $cache;
		
	return $self;
}

sub _n_optimisation
{
	my $self = shift;
	
	if ($self->data->{'kind'} eq 'individual')
	{
		my $fnIsNick = (defined $self->{'DATA_'}->{'fn'}) && ($self->{'DATA_'}->{'fn'} =~ /\b(nickname)\b/);
		
		unless (@{ $self->data->{'n'} } || $fnIsNick)
		{
			my $fn = $self->data->{'fn'};
			$fn =~ s/(^\s|\s$)//g;
			$fn =~ s/\s+/ /g;
			
			my @words = split / /, $fn;
			
			if (scalar @words == 1)
			{
				push @{ $self->data->{'nickname'} }, ms($words[0], $self->{'DATA_'}->{'fn'}) ;
			}
			elsif (scalar @words)
			{
				if (($words[0] =~ /^.*\,$/ || $words[1] =~ /^.\.?$/) && !defined $words[2])
				{
					$words[0] =~ s/[\.\,]$//;
					$words[1] =~ s/[\.\,]$//;
					
					push @{ $self->{'DATA'}->{'n'} },
						(bless {
							'DATA' => {
								'given-name'  => [ ms($words[1], $self->{'DATA_'}->{'fn'}) ],
								'family-name' => [ ms($words[0], $self->{'DATA_'}->{'fn'})  ],
								},
							'element' => $self->{'DATA_'}->{'fn'},
							'context' => $self->context,
							'cache'   => $self->cache,
							'id'      => $self->context->make_bnode($self->{'DATA_'}->{'fn'}),
							},
							'HTML::Microformats::hCard::n');
				}
				elsif (!defined $words[2])
				{
					push @{ $self->{'DATA'}->{'n'} },
						(bless {
							'DATA' => {
								'given-name'  => [ ms($words[0], $self->{'DATA_'}->{'fn'})  ],
								'family-name' => [ ms($words[1], $self->{'DATA_'}->{'fn'})  ],
								},
							'element' => $self->{'DATA_'}->{'fn'},
							'context' => $self->context,
							'cache'   => $self->cache,
							'id'      => $self->context->make_bnode($self->{'DATA_'}->{'fn'}),
							},
							'HTML::Microformats::hCard::n');
				}
			}
		}
	}
}

sub _detect_kind
{
	my $self = shift;
	my $rv   = $self->{'DATA'};
	
	# If 'kind' class provided explicitly, trust it.
	if (length $rv->{'kind'})
	{
		# With canonicalisation though.
		$rv->{'kind'} =~ s/(^\s|\s+$)//g;
		$rv->{'kind'} = lc $rv->{'kind'};
		return;
	}
	
	# If an 'fn' has been provided, guess.
	if (length $rv->{'fn'})
	{
		# Assume it's an individual.
		$rv->{'kind'} = 'individual';
		
		# But check to see if the fn matches an org name or unit.
		ORGLOOP: foreach my $org (@{ $rv->{'org'} })
		{
			if ("".$org->data->{'organization-name'} eq $rv->{'fn'})
			{
				$rv->{'kind'} = 'org';
				last ORGLOOP;
			}
			foreach my $ou (@{ $org->data->{'organization-unit'} })
			{
				if ("$ou" eq $rv->{'fn'})
				{
					$rv->{'kind'} = 'group';
					last ORGLOOP;
				}
			}
		}
		
		# If not, then check to see if the fn matches an address part.
		if ($rv->{'kind'} eq 'individual')
		{
			ADRLOOP: foreach my $adr (@{ $rv->{'adr'} })
			{
				foreach my $part (qw(post-office-box extended-address
					street-address locality region postal-code country-name))
				{
					foreach my $line (@{ $adr->data->{$part} })
					{
						if ("$line" eq $rv->{'fn'})
						{
							$rv->{'kind'} = 'location';
							last ADRLOOP;
						}
					}
				}
			}
		}
		
		return;
	}
	
	# Final assumption.
	$rv->{'kind'} = 'individual';
}

sub format_signature
{
	my $self  = shift;
	my $vcard = 'http://www.w3.org/2006/vcard/ns#';
	my $vx    = 'http://buzzword.org.uk/rdf/vcardx#';
	my $ix    = 'http://buzzword.org.uk/rdf/icalx#';
	my $geo   = 'http://www.w3.org/2003/01/geo/wgs84_pos#';

	# vCard 4.0 introduces CLIENTPIDMAP - best to ignore?

	my $rv = {
		'root' => 'vcard',
		'classes' => [
			['adr',         'm*',    {'embedded'=>'adr'}],
			['agent',       'MM*',   {'embedded'=>'hCard'}],
			['anniversary', 'd?'],   #extension
			['bday',        'd?'],
			['biota',       'm*',    {'embedded'=>'species', 'use-key'=>'species'}], #extension
			['birth',       'M?',    {'embedded'=>'hCard adr geo'}], #extension
			['caladruri',   'u*'],   #extension
			['caluri',      'MMu*',  {'embedded'=>'hCalendar'}], #extension
			['category',    '*'],
			['class',       '?'],
			['dday',        'd?'],   #extension
			['death',       'M?',    {'embedded'=>'hCard adr geo'}], #extension
			['email',       '*#'],
			['fn',          '1<'],
			['fburl',       'MMu*',  {'embedded'=>'hCalendar'}], #extension
			['gender',      '?'],    #extension
			['geo',         'm*',    {'embedded'=>'geo'}],
			['impp',        '*#'],   #extension
			['kind',        '?'],    #extension
			['key',         'u*'],
			['label',       '*#'],
			['lang',        '*'],    #extension
			['logo',        'u*'],
			['mailer',      '*'],
			['n',           '*#'],
			['nickname',    '*'],
			['note',        '*'],
			['org',         '*#'],
			['photo',       'u*'],
			['rev',         'd*'],
			['role',        '*'],
			['sex',         'n?'],   #extension (0=?,1=M,2=F,9=na)
			['sort-string', '?'],
			['sound',       'u*'],
			['tel',         '*#'],
			['title',       '*'],
			['tz',          '?'],
			['uid',         'U?'],
			['url',         'u*'],
		],
		'options' => {
			'rel-me'     => '_has_relme',
			'rel-tag'    => 'category',
			'hmeasure'   => 'measures', #extension
			'no-destroy' => ['adr', 'geo'],
		},
		'rdf:type' => ["${vcard}VCard"] ,
		'rdf:property' => {
			'adr'              => { 'resource' => ["${vcard}adr"] } ,
			'agent'            => { 'resource' => ["${vcard}agent"] , 'literal' => ["${vx}agent"] } ,
			'anniversary'      => { 'literal'  => ["${vx}anniversary"] },
			'bday'             => { 'literal'  => ["${vcard}bday"] },
			'birth'            => { 'resource' => ["${vx}birth"] ,    'literal'  => ["${vx}birth"] },
			'caladruri'        => { 'resource' => ["${vx}caladruri"] },
			'caluri'           => { 'resource' => ["${vx}caluri"] },
			'category'         => { 'resource' => ["${vx}category"] , 'literal' => ["${vcard}category"]},
			'class'            => { 'literal'  => ["${vcard}class"] },
			'dday'             => { 'literal'  => ["${vx}dday"] },
			'death'            => { 'resource' => ["${vx}death"] ,    'literal'  => ["${vx}death"] },
			'email'            => { 'resource' => ["${vcard}email"] },
			'fn'               => { 'literal'  => ["${vcard}fn", "http://www.w3.org/2000/01/rdf-schema#label"] },
			'fburl'            => { 'resource' => ["${vx}fburl"] },
			'gender'           => { 'literal'  => ["${vx}gender"] },
			'geo'              => { 'resource' => ["${vcard}geo"] } ,
			'impp'             => { 'resource' => ["${vx}impp"] },
			'kind'             => { 'literal'  => ["${vx}kind"] },
			'key'              => { 'resource' => ["${vcard}key"] },
			'label'            => { 'resource' => ["${vcard}label"] },
			'lang'             => { 'literal'  => ["${vx}lang"] },
			'logo'             => { 'resource' => ["${vcard}logo"] },
			'mailer'           => { 'literal'  => ["${vcard}mailer"] },
			'n'                => { 'resource' => ["${vcard}n"] },
			'nickname'         => { 'literal'  => ["${vcard}nickname"] },
			'note'             => { 'literal'  => ["${vcard}note"] },
			'org'              => { 'resource' => ["${vcard}org"] },
			'photo'            => { 'resource' => ["${vcard}photo"] },
			'rev'              => { 'literal'  => ["${vcard}rev"] },
			'role'             => { 'literal'  => ["${vcard}role"] },
			'sex'              => { 'literal'  => ["${vx}sex"] },
			'sort-string'      => { 'literal'  => ["${vcard}sort-string"] },
			'sound'            => { 'resource' => ["${vcard}sound"] },
			'species'          => { 'resource' => ["${vx}x-species"] },
			'tel'              => { 'resource' => ["${vcard}tel"] },
			'title'            => { 'literal'  => ["${vcard}title"] },
			'tz'               => { 'literal'  => ["${vcard}tz"] },
			'uid'              => { 'resource' => ["${vcard}uid"], 'literal'  => ["${vcard}uid"] },
			'url'              => { 'resource' => ["${vcard}url"] },
			'cn'               => { 'literal'  => ["${ix}cn"] },
			'cutype'           => { 'literal'  => ["${ix}cutype"] },
			'rsvp'             => { 'literal'  => ["${ix}rsvp"] },
			'delegated-from'   => { 'resource' => ["${ix}delegatedFrom"] , 'literal' => ["${ix}delegatedFrom"] },
			'sent-by'          => { 'resource' => ["${ix}sentBy"] ,        'literal' => ["${ix}sentBy"] },
		},
	};
	
	if (ref $self and $self->{'in_hcalendar'})
	{
		push @{ $rv->{'classes'} }, ( # these are ALL extensions
			['cn',          '?'],
			['cutype',      '?'],
			['member',      '?'],
			['rsvp',        '?'],
			['delegated-from', 'Mu?',{'embedded'=>'hCard'}],
			['sent-by',     'Mu?',   {'embedded'=>'hCard'}],
			);
		$rv->{'rdf:property'}->{'member'} = { 'resource' => ["${ix}member"] , 'literal' => ["${ix}member"] };
	}
	else
	{
		push @{ $rv->{'classes'} }, (
			['member',      'Mu*',   {'embedded'=>'hCard'}], #extension
			);
		$rv->{'rdf:property'}->{'member'} = { 'resource' => ["${vx}member"] , 'literal' => ["${vx}member"] };
	}
	
	return $rv;
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);
	
	foreach my $property (qw(n org adr geo agent tel email label impp birth caluri death fburl delegated-from sent-by member species))
	{
		foreach my $value (@{ $self->data->{$property} })
		{
			if (UNIVERSAL::can($value, 'add_to_model'))
			{
				$value->add_to_model($model);
			}
		}
	}
	
	# From the vCard we can infer data about its holder.
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, 'holder'),
			RDF::Trine::Node::Resource->new('http://purl.org/uF/hCard/terms/hasCard'),
			$self->id(1),
			));
		
		if (lc $self->data->{'kind'} eq 'individual')
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'holder'),
				RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
				RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/Person'),
				));
		}
		elsif (lc $self->data->{'kind'} eq 'org')
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'holder'),
				RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
				RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/Organization'),
				));
		}
		elsif (lc $self->data->{'kind'} eq 'group')
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'holder'),
				RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
				RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/Group'),
				));
		}
		elsif (lc $self->data->{'kind'} eq 'location')
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'holder'),
				RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
				RDF::Trine::Node::Resource->new('http://www.w3.org/2003/01/geo/wgs84_pos#SpatialThing'),
				));
		}

		foreach my $species (@{ $self->data->{'species'} })
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'holder'),
				RDF::Trine::Node::Resource->new('http://purl.org/NET/biol/ns#hasTaxonomy'),
				$species->id(1),
				));
		}
	}
	
	$self->context->representative_hcard;
	if ($self->{'representative'})
	{
		$model->add_statement(RDF::Trine::Statement->new(
			RDF::Trine::Node::Resource->new($self->context->uri),
			RDF::Trine::Node::Resource->new('http://purl.org/uF/hCard/terms/representative'),
			$self->id(1),
			));
	}
	
	return $self;
}

sub profiles
{
	my $class = shift;
	return qw(http://microformats.org/profile/hcard
		http://ufs.cc/x/hcard
		http://www.w3.org/2006/03/hcard
		http://purl.org/uF/hCard/1.0/
		http://purl.org/uF/2008/03/);
}

1;

=head1 MICROFORMAT

HTML::Microformats::hCard supports hCard as described at
L<http://microformats.org/wiki/hcard>, with the following additions:

=over 4

=item * vCard 4.0 terms

This module includes additional property terms taken from the latest
vCard 4.0 drafts. For example the property 'impp' may be used to mark up
instant messaging addresses for a contact.

The vCard 4.0 property 'kind' is used to record the kind of contact described
by the hCard (an individual, an organisation, etc). In many cases this is
automatically inferred.

=item * Embedded species microformat

If the species microformat (see L<HTML::Microformats::species>) is found
embedded within an hCard, then this is taken to be the species of a contact.

=item * Embedded hMeasure

If the hMeasure microformat (see L<HTML::Microformats::hMeasure>) is
found embedded within an hCard, and no 'item' property is provided, then
the measurement is taken to pertain to the contact described by the hCard.

=back

=head1 RDF OUTPUT

Data is returned using the W3C's vCard vocabulary
(L<http://www.w3.org/2006/vcard/ns#>) with some supplemental
terms from Toby Inkster's vCard extensions vocabulary
(L<http://buzzword.org.uk/rdf/vcardx#>) and occasional other terms.

After long deliberation on the "has-a/is-a issue", the author of this
module decided that the holder of a vCard and the vCard itself should
be modelled as two separate resources, and this is how the data is
returned.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::_base>,
L<HTML::Microformats>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

