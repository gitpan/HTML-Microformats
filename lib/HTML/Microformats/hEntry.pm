=head1 NAME

HTML::Microformats::hEntry - an hAtom entry

=head1 SYNOPSIS

 use Data::Dumper;
 use HTML::Microformats::_context;
 use HTML::Microformats::hAtom;

 my $context = HTML::Microformats::_context->new($dom, $uri);
 my @feeds   = HTML::Microformats::hAtom->extract_all(
                   $dom->documentElement, $context);
 foreach my $feed (@feeds)
 {
   foreach my $entry ($feed->get_entry)
   {
     print $entry->get_link . "\n";
   }
 }

=head1 DESCRIPTION

HTML::Microformats::hEntry is a helper module for HTML::Microformats::hAtom.
This class is used to represent entries within feeds. Generally speaking, you want to
use HTML::Microformats::hAtom instead.

HTML::Microformats::hEntry inherits from HTML::Microformats::BASE. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::hEntry;

use base qw(HTML::Microformats::BASE HTML::Microformats::Mixin::Parser);
use common::sense;
use 5.008;

use HTML::Microformats::_util qw(searchClass searchAncestorClass stringify);
use HTML::Microformats::Datatypes::String qw(isms);
use HTML::Microformats::hCard;
use HTML::Microformats::hEvent;
use HTML::Microformats::hNews;

sub new
{
	my ($class, $element, $context) = @_;
	my $cache = $context->cache;
	
	# Use hNews if more appropriate.
	if ($element->getAttribute('class') =~ /\b(hnews)\b/)
	{
		return HTML::Microformats::hNews->new($element, $context)
			if $context->has_profile( HTML::Microformats::hNews->profiles );
	}
	
	return $cache->get($context, $element, $class)
		if defined $cache && $cache->get($context, $element, $class);
	
	my $self = {
		'element'    => $element ,
		'context'    => $context ,
		'cache'      => $cache ,
		'id'         => $context->make_bnode($element) ,
		};
	
	bless $self, $class;
		
	$self->_hentry_parse;
	
	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub _hentry_parse
{
	my ($self) = @_;

	my $clone = $self->{'element'}->cloneNode(1);	
	$self->_expand_patterns($clone);
	
	# Because of <address> element handling, process 'author' outside of
	# _simple_parse.
	$self->_author_parse($clone);
	
	# Parse other properties.
	$self->_simple_parse($clone);
	
	# Fallback for title - use the first <hX> element
	# or (if there's no hfeed) the page title.
	$self->_title_fallback($clone);
	
	# Fallback for permalink - use id attribute or page URI.
	$self->_link_fallback($self->{'element'});

	# Handle replies hAtom feed
	$self->_reply_handler;

	if ($self->context->has_profile( HTML::Microformats::VoteLinks->profiles ))
	{
		my @vls = HTML::Microformats::VoteLinks->extract_all($clone, $self->context);
		foreach my $votelink (@vls)
		{
			next if defined $votelink->data->{'voter'};
			
			my $ancestor = searchAncestorClass('hentry', $votelink->element)
			            || searchAncestorClass('hnews', $votelink->element)
							|| searchAncestorClass('hslice', $votelink->element);
			next unless defined $ancestor;
			next unless $ancestor->getAttribute('data-cpan-html-microformats-nodepath')
				      eq $self->element->getAttribute('data-cpan-html-microformats-nodepath');
			
			$votelink->data->{'voter'} = $self->data->{'author'};
		}
	}
	
	return $clone;
}

sub _author_parse
{
	my ($self, $clone) = @_;
	
	my @vcard_elements = searchClass('vcard', $clone);
	foreach my $ve (@vcard_elements)
	{
		next unless $ve->getAttribute('class') =~ /\b(author)\b/;
		next unless $clone->getAttribute('data-cpan-html-microformats-nodepath') eq searchAncestorClass('hentry', $ve)->getAttribute('data-cpan-html-microformats-nodepath');
		
		push @{ $self->{'DATA'}->{'author'} }, HTML::Microformats::hCard->new($ve, $self->context);
	}
	unless (@{ $self->{'DATA'}->{'author'} })
	{
		foreach my $ve (@vcard_elements)
		{
			next unless $ve->tagName eq 'address';		
			next unless $clone->getAttribute('data-cpan-html-microformats-nodepath') eq searchAncestorClass('hentry', $ve)->getAttribute('data-cpan-html-microformats-nodepath');
			
			push @{ $self->{'DATA'}->{'author'} }, HTML::Microformats::hCard->new($ve, $self->context);
		}
	}
	
	unless (@{ $self->{'DATA'}->{'author'} })
	{
		##TODO: Should really only use the nearest-in-parent
		my @address_elements = $self->context->document->getElementsByTagName('address');
		foreach my $address (@address_elements)
		{
			next unless $address->getAttribute('class') =~ /\b(author)\b/;
			next unless $address->getAttribute('class') =~ /\b(vcard)\b/;
			
			push @{ $self->{'DATA'}->{'author'} }, HTML::Microformats::hCard->new($address, $self->context);
		}
	}
}

sub _title_fallback
{
	my ($self, $element) = @_;
	
	unless (defined $self->data->{'title'})
	{
		ELEM: foreach my $tag ($element->getElementsByTagName('*'))
		{
			if ($tag->tagName =~ /^h[1-9]?$/i)
			{
				$self->data->{'title'} = stringify($tag, 'value');
				last ELEM;
			}
		}
	}
	unless (defined $self->data->{'title'}
	or      searchAncestorClass('hfeed', $element))
	{
		TITLE: foreach my $tag ($self->context->document->getElementsByTagName('title'))
		{
			my $str = stringify($tag, 'value');
			$self->data->{'title'} = $str;
			last TITLE if length $str;
		}
	}
}

sub _link_fallback
{
	my ($self, $element) = @_;
	
	unless (defined $self->data->{'link'})
	{
		if ($element->hasAttribute('id'))
		{
			$self->data->{'link'} = $self->context->uri('#'.$element->getAttribute('id'));
		}
		else
		{
			$self->data->{'link'} = $self->context->document_uri;
		}
	}
}

sub _reply_handler
{
	my ($self) = @_;
	
	FEED: foreach my $feed (@{$self->data->{'replies'}})
	{
		ENTRY: foreach my $entry (@{$feed->data->{'entry'}})
		{
			push @{ $entry->data->{'in-reply-to'} }, $self->data->{'link'},
				if  defined $self->data->{'link'}
				&& !defined $entry->data->{'in-reply-to'};
		}
	}
}

sub format_signature
{
	my $awol = 'http://bblfish.net/work/atom-owl/2006-06-06/#';
	my $ax   = 'http://buzzword.org.uk/rdf/atomix#';
	my $iana = 'http://www.iana.org/assignments/relation/';
	my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';
	
	return {
		'root' => ['hentry','hslice','hnews'],
		'classes' => [
			['bookmark',        'ru?',  {'use-key'=>'link'}],
			['entry-content',   'H&',   {'use-key'=>'content'}],
			['entry-summary',   'H&',   {'use-key'=>'summary'}],
			['entry-title',     '?',    {'use-key'=>'title'}],
			['in-reply-to',     'Ru*'], #extension
			['published',       'd?'],
			['replies',         'm*',   {'embedded'=>'hAtom'}], #extension
			['updated',         'd*',   {'datetime-feedthrough' => 'published'}],
			['author',          '#*'],
		],
		'options' => {
			'rel-tag'       => 'category',
			'rel-enclosure' => 'enclosure', #extension
			# 'rel-license'   => 'license', #extension
		},
		'rdf:type' => ["${awol}Entry"] ,
		'rdf:property' => {
			'link'        => { resource => ["${iana}self"] } ,
			'title'       => { literal  => ["${rdfs}label"] } ,
			'in-reply-to' => { resource => ["${ax}in-reply-to"] } ,
			'published'   => { literal  => ["${awol}published"] } ,
			'updated'     => { literal  => ["${awol}updated"] } ,
			'category'    => { resource => ["${awol}category"] } ,
			'enclosure'   => { resource => ["${iana}enclosure"] } ,
			},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);

	my $awol = 'http://bblfish.net/work/atom-owl/2006-06-06/#';
	my $ax   = 'http://buzzword.org.uk/rdf/atomix#';
	my $iana = 'http://www.iana.org/assignments/relation/';
	my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';
	my $rdf  = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
	
	foreach my $field (qw(title summary))
	{
		next unless length $self->data->{"html_$field"};
		
		$self->{'id.'.$field} = $self->context->make_bnode
			unless defined $self->{'id.'.$field};
		
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${awol}${field}"),
			$self->id(1, $field),
			));
			
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, $field),
			RDF::Trine::Node::Resource->new("${rdf}type"),
			RDF::Trine::Node::Resource->new("${awol}TextContent"),
			));
		
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, $field),
			RDF::Trine::Node::Resource->new("${awol}xhtml"),
			RDF::Trine::Node::Literal->new($self->data->{"html_$field"}, undef, "${rdf}XMLLiteral"),
			));

		if (isms($self->data->{$field}))
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, $field),
				RDF::Trine::Node::Resource->new("${awol}text"),
				RDF::Trine::Node::Literal->new($self->data->{$field}->to_string, $self->data->{$field}->lang),
				))
		}
		elsif (defined $self->data->{$field})
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, $field),
				RDF::Trine::Node::Resource->new("${awol}text"),
				RDF::Trine::Node::Literal->new($self->data->{$field}),
				))
		}
	}

	foreach my $field (qw(content))
	{
		next unless length $self->data->{"html_$field"};
		
		$self->{'id.'.$field} = $self->context->make_bnode
			unless defined $self->{'id.'.$field};

		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${awol}${field}"),
			$self->id(1, $field),
			));
			
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, $field),
			RDF::Trine::Node::Resource->new("${rdf}type"),
			RDF::Trine::Node::Resource->new("${awol}Content"),
			));
		
		if (defined $self->data->{"html_$field"})
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, $field),
				RDF::Trine::Node::Resource->new("${awol}type"),
				RDF::Trine::Node::Literal->new("application/xhtml+xml"),
				));
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, $field),
				RDF::Trine::Node::Resource->new("${awol}body"),
				RDF::Trine::Node::Literal->new($self->data->{"html_$field"}, undef, "${rdf}XMLLiteral"),
				));
		}
		else
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, $field),
				RDF::Trine::Node::Resource->new("${awol}type"),
				RDF::Trine::Node::Literal->new("text/plain"),
				));
			if (isms($self->data->{$field}))
			{
				$model->add_statement(RDF::Trine::Statement->new(
					$self->id(1, $field),
					RDF::Trine::Node::Resource->new("${awol}body"),
					RDF::Trine::Node::Literal->new($self->data->{$field}->to_string, $self->data->{$field}->lang),
					));
			}
			elsif (defined $self->data->{$field})
			{
				$model->add_statement(RDF::Trine::Statement->new(
					$self->id(1, $field),
					RDF::Trine::Node::Resource->new("${awol}body"),
					RDF::Trine::Node::Literal->new($self->data->{$field}),
					));
			}
		}
	}

	foreach my $author (@{ $self->data->{'author'} })
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${awol}author"),
			$author->id(1, 'holder'),
			));
		$author->add_to_model($model);
	}

	foreach my $field (qw(link))
	{
		$self->{'id.'.$field} = $self->context->make_bnode
			unless defined $self->{'id.'.$field};
		$self->{'id.'.$field.'-dest'} = $self->context->make_bnode
			unless defined $self->{'id.'.$field.'-dest'};
		
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${awol}link"),
			$self->id(1, $field),
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, $field),
			RDF::Trine::Node::Resource->new("${rdf}type"),
			RDF::Trine::Node::Resource->new("${awol}Link"),
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, $field),
			RDF::Trine::Node::Resource->new("${awol}rel"),
			RDF::Trine::Node::Resource->new($iana . ($field eq 'link' ? 'self' : $field)),
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, $field),
			RDF::Trine::Node::Resource->new("${awol}to"),
			$self->id(1, "${field}-dest"),
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, "${field}-dest"),
			RDF::Trine::Node::Resource->new("${rdf}type"),
			RDF::Trine::Node::Resource->new("${awol}Content"),
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, "${field}-dest"),
			RDF::Trine::Node::Resource->new("${awol}src"),
			RDF::Trine::Node::Resource->new($self->data->{$field}),
			));
	}

	foreach my $field (qw(enclosure))
	{
		for (my $i=0; defined $self->data->{$field}->[$i]; $i++)
		{
			$self->{'id.'.$field.'.'.$i} = $self->context->make_bnode
				unless defined $self->{'id.'.$field.'.'.$i};
			$self->{'id.'.$field.'-dest.'.$i} = $self->context->make_bnode
				unless defined $self->{'id.'.$field.'-dest.'.$i};
			
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new("${awol}link"),
				$self->id(1, $field.'.'.$i),
				));
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, $field.'.'.$i),
				RDF::Trine::Node::Resource->new("${rdf}type"),
				RDF::Trine::Node::Resource->new("${awol}Link"),
				));
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, $field.'.'.$i),
				RDF::Trine::Node::Resource->new("${awol}rel"),
				RDF::Trine::Node::Resource->new($iana . ($field eq 'link' ? 'self' : $field)),
				));
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, $field.'.'.$i),
				RDF::Trine::Node::Resource->new("${awol}to"),
				$self->id(1, "${field}-dest.${i}"),
				));
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, "${field}-dest.${i}"),
				RDF::Trine::Node::Resource->new("${rdf}type"),
				RDF::Trine::Node::Resource->new("${awol}Content"),
				));
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, "${field}-dest.${i}"),
				RDF::Trine::Node::Resource->new("${awol}src"),
				RDF::Trine::Node::Resource->new($self->data->{$field}->[$i]),
				));
		}
	}
	
	HTML::Microformats::hEvent::_add_to_model_related($self, $model);

	return $self;
}

sub profiles
{
	my @p = qw(http://microformats.org/profile/hatom
		http://ufs.cc/x/hatom
		http://purl.org/uF/hAtom/0.1/);
	push @p, HTML::Microformats::hNews->profiles;
	return @p;
}

1;

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::BASE>,
L<HTML::Microformats>,
L<HTML::Microformats::hAtom>,
L<HTML::Microformats::hNews>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut