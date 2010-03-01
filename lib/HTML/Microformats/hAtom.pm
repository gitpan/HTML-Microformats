=head1 NAME

HTML::Microformats::hAtom - the hAtom microformat

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

HTML::Microformats::hAtom inherits from HTML::Microformats::_base. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::hAtom;

use base qw(HTML::Microformats::_base HTML::Microformats::_simple_parser);
use common::sense;
use 5.008;

use HTML::Microformats::_util qw(searchAncestorClass);
use HTML::Microformats::Datatypes::String qw(isms);
use HTML::Microformats::hCard;
use HTML::Microformats::hEntry;
use HTML::Microformats::hNews;

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
		
	my $clone = $self->{'element'}->cloneNode(1);	
	$self->_expand_patterns($clone);
	$self->_simple_parse($clone);
	
	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub extract_all
{
	my ($class, $element, $context) = @_;
	
	my @feeds = HTML::Microformats::_base::extract_all($class, $element, $context);
	
	if ($element->tagName eq 'html' || !@feeds)
	{
		my @entries = HTML::Microformats::hEntry->extract_all($element, $context);
		my $orphans = 0;
		foreach my $entry (@entries)
		{
			$orphans++ unless searchAncestorClass('hfeed', $entry->element);
		}
		if ($orphans)
		{
			my $slurpy = $class->new($element, $context);
			unshift @feeds, $slurpy;
		}
	}
	
	return @feeds;
}

sub format_signature
{
	my $awol = 'http://bblfish.net/work/atom-owl/2006-06-06/#';
	my $ax   = 'http://buzzword.org.uk/rdf/atomix#';
	my $iana = 'http://www.iana.org/assignments/relation/';
	my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';
	
	return {
		'root' => ['hfeed'],
		'classes' => [
			['hentry',  'm*',   {'embedded'=>'hEntry', 'use-key'=>'entry'}],
		],
		'options' => {
			'rel-tag' => 'category',
		},
		'rdf:type' => ["${awol}Feed"] ,
		'rdf:property' => {
			'entry'       => { resource => ["${awol}entry"] } ,
			'category'    => { resource => ["${awol}category"] } ,
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
	
	foreach my $author (@{ $self->data->{'author'} })
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${awol}author"),
			$author->id(1, 'holder'),
			));
		$author->add_to_model($model);
	}

	return $self;
}

sub profiles
{
	my @p = qw();
	push @p, HTML::Microformats::hEntry->profiles;
	push @p, HTML::Microformats::hNews->profiles;
	return @p;
}

1;

=head1 MICROFORMAT

HTML::Microformats::hAtom supports hAtom as described at
L<http://microformats.org/wiki/hatom>, with the following additions:

=over 4

=item * Embedded rel-enclosure microformat

hAtom entries may use rel-enclosure to specify entry enclosures.

=item * Threading support

An entry may use rel="in-reply-to" to indicate another entry or a document that
this entry is considered a reply to.

An entry may use class="replies hfeed" to provide an hAtom feed of responses to it.

=back

=head1 RDF OUTPUT

Data is returned using Henry Story's AtomOWL vocabulary
(L<http://bblfish.net/work/atom-owl/2006-06-06/#>), Toby Inkster's
AtomOWL extensions (L<http://buzzword.org.uk/rdf/atomix#>) and
the IANA registered relationship URIs (L<http://www.iana.org/assignments/relation/>).

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::_base>,
L<HTML::Microformats>,
L<HTML::Microformats::hEntry>,
L<HTML::Microformats::hNews>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
