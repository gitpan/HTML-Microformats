=head1 NAME

HTML::Microformats::RelEnclosure - the rel-enclosure microformat

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

HTML::Microformats::RelEnclosure inherits from HTML::Microformats::RELBASE. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=head2 Additional Method

=over 4

=item C<< $relenc->get_type() >>

Returns the media type (Content-Type) of the resource being linked to. This
is taken from the HTML 'type' attribute, so if that's not present, returns undef.

=back

=cut

package HTML::Microformats::RelEnclosure;

use base qw(HTML::Microformats::RELBASE);
use common::sense;
use 5.008;

use HTML::Microformats::Datatypes::String qw(isms);

our $VERSION = '0.00_12';

sub new
{
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	
	$self->{'DATA'}->{'type'} = $self->{'element'}->getAttribute('type')
		if $self->{'element'}->hasAttribute('type');

	return $self;
}

sub format_signature
{
	return {
		'rel'      => 'enclosure' ,
		'classes'  => [
				['type',     '?#'] ,
				['href',     '1#'] ,
				['label',    '1#'] ,
				['title',    '1#'] ,
			] ,
		'rdf:type' => [] ,
		'rdf:property' => {} ,
		}
}

sub profiles
{
	return qw(http://purl.org/uF/rel-enclosure/0.1/);
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	my $enc  = 'http://purl.oclc.org/net/rss_2.0/enc#';
	
	$model->add_statement(RDF::Trine::Statement->new(
		RDF::Trine::Node::Resource->new($self->context->document_uri),
		RDF::Trine::Node::Resource->new("${enc}enclosure"),
		RDF::Trine::Node::Resource->new($self->data->{'href'}),
		));
		
	$model->add_statement(RDF::Trine::Statement->new(
		RDF::Trine::Node::Resource->new($self->data->{'href'}),
		RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"),
		RDF::Trine::Node::Resource->new("${enc}Enclosure"),
		));

	$model->add_statement(RDF::Trine::Statement->new(
		RDF::Trine::Node::Resource->new($self->data->{'href'}),
		RDF::Trine::Node::Resource->new("${enc}type"),
		RDF::Trine::Node::Literal->new(''.$self->data->{'type'}),
		))
		if defined $self->data->{'type'};

	if (isms($self->data->{'label'}))
	{
		$model->add_statement(RDF::Trine::Statement->new(
			RDF::Trine::Node::Resource->new($self->data->{'href'}),
			RDF::Trine::Node::Resource->new("http://www.w3.org/2000/01/rdf-schema#label"),
			RDF::Trine::Node::Literal->new($self->data->{'label'}->to_string, $self->data->{'label'}->lang),
			));
	}
	elsif (defined $self->data->{'label'})
	{
		$model->add_statement(RDF::Trine::Statement->new(
			RDF::Trine::Node::Resource->new($self->data->{'href'}),
			RDF::Trine::Node::Resource->new("http://www.w3.org/2000/01/rdf-schema#label"),
			RDF::Trine::Node::Literal->new($self->data->{'label'}),
			));
	}

	if (isms($self->data->{'title'}))
	{
		$model->add_statement(RDF::Trine::Statement->new(
			RDF::Trine::Node::Resource->new($self->data->{'href'}),
			RDF::Trine::Node::Resource->new("http://purl.org/dc/terms/title"),
			RDF::Trine::Node::Literal->new($self->data->{'title'}->to_string, $self->data->{'title'}->lang),
			));
	}
	elsif (defined $self->data->{'title'})
	{
		$model->add_statement(RDF::Trine::Statement->new(
			RDF::Trine::Node::Resource->new($self->data->{'href'}),
			RDF::Trine::Node::Resource->new("http://purl.org/dc/terms/title"),
			RDF::Trine::Node::Literal->new($self->data->{'title'}),
			));
	}

	return $self;
}

1;

=head1 MICROFORMAT

HTML::Microformats::RelEnclosure supports rel-enclosure as described at
L<http://microformats.org/wiki/rel-enclosure>.

The "title" attribute on the link, and the linked text are taken to be significant.

=head1 RDF OUTPUT

Data is returned using the RSS Enclosures vocabulary
(L<http://purl.oclc.org/net/rss_2.0/enc#>) and occasional other terms.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::RELBASE>,
L<HTML::Microformats>,
L<HTML::Microformats::hAtom>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

