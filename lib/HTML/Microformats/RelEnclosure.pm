package HTML::Microformats::RelEnclosure;

use base qw(HTML::Microformats::_rel);
use common::sense;
use 5.008;

use HTML::Microformats::Datatypes::String qw(isms);

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
		RDF::Trine::Node::Resource->new($self->context->uri),
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