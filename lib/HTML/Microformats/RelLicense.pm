package HTML::Microformats::RelLicense;

use base qw(HTML::Microformats::RELBASE);
use common::sense;
use 5.008;

sub format_signature
{
	return {
		'rel'      => 'license' ,
		'classes'  => [
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
	return qw(http://microformats.org/profile/rel-license
		http://ufs.cc/x/rel-license
		http://microformats.org/profile/specs
		http://ufs.cc/x/specs
		http://purl.org/uF/rel-license/1.0/
		http://purl.org/uF/2008/03/);
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;
	
	$model->add_statement(RDF::Trine::Statement->new(
		RDF::Trine::Node::Resource->new($self->context->uri),
		RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"),
		RDF::Trine::Node::Resource->new("http://creativecommons.org/ns#Work"),
		));
		
	$model->add_statement(RDF::Trine::Statement->new(
		RDF::Trine::Node::Resource->new($self->data->{'href'}),
		RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"),
		RDF::Trine::Node::Resource->new("http://creativecommons.org/ns#License"),
		));

	foreach my $uri (qw(http://creativecommons.org/ns#license
		http://www.w3.org/1999/xhtml/vocab#license
		http://purl.org/dc/terms/license))
	{
		$model->add_statement(RDF::Trine::Statement->new(
			RDF::Trine::Node::Resource->new($self->context->uri),
			RDF::Trine::Node::Resource->new($uri),
			RDF::Trine::Node::Resource->new($self->data->{'href'}),
			));
	}
		
	return $self;
}


1;
