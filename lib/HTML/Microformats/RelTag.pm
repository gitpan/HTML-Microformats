package HTML::Microformats::RelTag;

use base qw(HTML::Microformats::RELBASE);
use common::sense;
use 5.008;

use CGI::Util qw(unescape);

sub new
{
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	
	my $tag = $self->{'DATA'}->{'href'};
	$tag =~ s/\#.*$//;
	$tag =~ s/\?.*$//;
	$tag =~ s/\/$//;
	if ($tag =~ m{^(.*/)([^/]+)$})
	{
		$self->{'DATA'}->{'tagspace'} = $1;
		$self->{'DATA'}->{'tag'}      = unescape($2);
	}

	return $self;
}

sub format_signature
{
	my $t    = 'http://www.holygoat.co.uk/owl/redwood/0.1/tags/';
	my $awol = 'http://bblfish.net/work/atom-owl/2006-06-06/#';
	
	return {
		'rel'      => 'tag' ,
		'classes'  => [
				['tag',      '1#'] ,
				['tagspace', '1#'] ,
				['href',     '1#'] ,
				['label',    '1#'] ,
				['title',    '1#'] ,
			] ,
		'rdf:type' => ["${t}Tag","${awol}Category"] ,
		'rdf:property' => {
			'tag'      => { 'literal'  => ["${awol}term", "${t}name", "http://www.w3.org/2000/01/rdf-schema#label"] },
			'tagspace' => { 'resource' => ["${awol}scheme"] },
			'href'     => { 'resource' => ["http://xmlns.com/foaf/0.1/page"] },
			} ,
		}
}

sub profiles
{
	return qw(http://microformats.org/profile/rel-tag
		http://ufs.cc/x/rel-tag
		http://microformats.org/profile/specs
		http://ufs.cc/x/specs
		http://purl.org/uF/rel-tag/1.0/
		http://purl.org/uF/2008/03/);
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);
	
	$model->add_statement(RDF::Trine::Statement->new(
		RDF::Trine::Node::Resource->new($self->context->document_uri),
		RDF::Trine::Node::Resource->new('http://www.holygoat.co.uk/owl/redwood/0.1/tags/taggedWithTag'),
		$self->id(1),
		));

	return $self;
}

1;
