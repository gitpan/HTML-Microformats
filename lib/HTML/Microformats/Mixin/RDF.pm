package HTML::Microformats::Mixin::RDF;

use common::sense;
use 5.008;

use RDF::Trine;

sub _simple_rdf
{
	my $self  = shift;
	my $model = shift;

	my $id    = $self->id(1);

	foreach my $rdftype (@{ $self->format_signature->{'rdf:type'} })
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$id,
			RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
			RDF::Trine::Node::Resource->new($rdftype),
			));
	}

	KEY: foreach my $key (sort keys %{ $self->format_signature->{'rdf:property'} })
	{
		my $rdf  = $self->format_signature->{'rdf:property'}->{$key};

		next KEY unless defined $self->data->{$key};

		my $vals = $self->data->{$key};
		$vals = [$vals] unless ref $vals eq 'ARRAY';

		foreach my $val (@$vals)
		{
			my $can_id      = ref $val && $val->can('id');
			my $seems_bnode = ($val =~ /^_:\S+$/);
			my $seems_uri   = ($val =~ /^[a-z0-9\.\+\-]{1,20}:\S+$/);

			if (defined $rdf->{'resource'} && ($can_id || $seems_uri || $seems_bnode))
			{
				foreach my $prop (@{ $rdf->{'resource'} })
				{
					my $val_node = undef;
					if ($can_id)
					{
						$val_node = $val->id(1);
					}
					else
					{
						$val_node = ($val =~ /^_:(.*)$/) ? 
							RDF::Trine::Node::Blank->new($1) : 
							RDF::Trine::Node::Resource->new($val);
					}

					$model->add_statement(RDF::Trine::Statement->new(
						$id,
						RDF::Trine::Node::Resource->new($prop),
						$val_node
						));

					if ($can_id && $val->can('add_to_model'))
					{
						$val->add_to_model($model);
					}
				}
			}
			
			elsif (defined $rdf->{'literal'} and !$can_id)
			{
				foreach my $prop (@{ $rdf->{'literal'} })
				{
					my $trine_node;
					
					if (UNIVERSAL::can($val, 'to_string')
					and UNIVERSAL::can($val, 'datatype'))
					{
						$trine_node = RDF::Trine::Node::Literal->new(
							$val->to_string, undef, $val->datatype);
					}
					elsif (UNIVERSAL::can($val, 'to_string')
					   and UNIVERSAL::can($val, 'lang'))
					{
						$trine_node = RDF::Trine::Node::Literal->new(
							$val->to_string, $val->lang);
					}
					else
					{
						my $dt = $rdf->{'literal_datatype'};
						if (defined $dt and length $dt and $dt !~ /:/)
						{
							$dt = 'http://www.w3.org/2001/XMLSchema#'.$dt;
						}
						if ($dt eq 'http://www.w3.org/2001/XMLSchema#integer')
						{
							$dt = int $dt;
						}
						
						$trine_node = RDF::Trine::Node::Literal->new($val, undef, $dt);
					}
					
					$model->add_statement(RDF::Trine::Statement->new(
						$id,
						RDF::Trine::Node::Resource->new($prop),
						$trine_node,
						));
				}
			}
		}
	}
}

1;

__END__

=head1 NAME

HTML::Microformats::Mixin::RDF - RDF output mixin

=head1 DESCRIPTION

HTML::Microformats::Mixin::RDF provides some utility code for microformat
modules to more easily output RDF.

HTML::Microformats::BASE inherits from this, so by extension, all the
microformat modules do too.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats>

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
