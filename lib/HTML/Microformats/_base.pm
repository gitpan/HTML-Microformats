package HTML::Microformats::_base;

use base qw(HTML::Microformats::_simple_rdf);
use common::sense;
use 5.008;

use Carp;
use HTML::Microformats::_util qw(searchClass searchRel);
use RDF::Trine;

our $AUTOLOAD;

# Derived classes...
#   MUST override: new
#   SHOULD override: format_signature, add_to_model, profiles
#   MIGHT WANT TO override: id, extract_all, data

sub new
{
	die "Cannot instantiate _base.\n";
}

sub extract_all
{
	my ($class, $dom, $context) = @_;
	my @rv;
	
	my $hclass = $class->format_signature->{'root'};
	my $rel    = $class->format_signature->{'rel'};
	
	if (defined $hclass)
	{
		$hclass = [$hclass] unless ref $hclass eq 'ARRAY';
		
		foreach my $hc (@$hclass)
		{
			my @elements = searchClass($hc, $dom);
			foreach my $e (@elements)
			{
				my $object = $class->new($e, $context);
				next if grep { $_->id eq $object->id } @rv; # avoid duplicates
				push @rv, $object if ref $object;
			}
		}
	}
	elsif (defined $rel)
	{
		$rel = [$rel] unless ref $rel eq 'ARRAY';
		
		foreach my $r (@$rel)
		{
			my @elements = searchRel($r, $dom);
			foreach my $e (@elements)
			{
				my $object = $class->new($e, $context);
				next if grep { $_->id eq $object->id } @rv; # avoid duplicates
				push @rv, $object if ref $object;
			}
		}
	}
	else
	{
		die "extract_all failed.\n";
	}
	
	return @rv;
}

sub format_signature
{
	return {
		'root'         => undef ,
		'rel'          => undef ,
		'classes'      => [] ,
		'options'      => {} ,
		'rdf:type'     => 'http://www.w3.org/2002/07/owl#Thing' ,
		'rdf:property' => {} ,
		};
}

sub profiles
{
	return qw();
}

sub context
{
	return $_[0]->{'context'};
}

sub data
{
	return {} unless defined $_[0]->{'DATA'};
	return $_[0]->{'DATA'};
}

sub TO_JSON
{
	return data( $_[0] );
}

sub element
{
	return $_[0]->{'element'};
}

sub cache
{
	return $_[0]->{'cache'};
}

sub id
{
	my ($self, $as_trine, $role) = @_;

	my $id = defined $role ? $self->{"id.${role}"} : $self->{'id'};

	return $id unless $as_trine;
	return ($id  =~ /^_:(.*)$/) ?
	       RDF::Trine::Node::Blank->new($1) :
	       RDF::Trine::Node::Resource->new($id);
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);
	
	return $self;
}

sub model
{
	my $self  = shift;
	my $model = RDF::Trine::Model->temporary_model;
	$self->add_to_model($model);
	return $model;
}

sub AUTOLOAD
{
	my $self = shift;
	my $func = $AUTOLOAD;
	
	if ($func =~ /^.*::(get|set|add|clear)_([^:]+)$/)
	{		
		my $method = $1;
		my $datum  = $2;
		my $opts   = undef;
		my $classes = $self->format_signature->{'classes'};
		
		$datum =~ s/_/\-/g;
		
		foreach my $c (@$classes)
		{
			if ($c->[0] eq $datum)
			{
				$opts = $c->[1];
				last;
			}
		}
		
		croak "Function $func unknown.\n" unless defined $opts;
		
		if ($method eq 'get')
		{
			return $self->{'DATA'}->{$datum};
		}
		elsif ($method eq 'clear')
		{
			croak "Attempt to clear required property $datum.\n"
				if $opts =~ /[1\+]/;
			delete $self->{'DATA'}->{$datum};
		}
		elsif ($method eq 'add')
		{
			croak "Attempt to add more than one value to singular property $datum.\n"
				if $opts =~ /[1\?]/ && defined $self->{'DATA'}->{$datum};
			
			if ($opts =~ /[1\?]/)
			{
				$self->{'DATA'}->{$datum} = shift;
			}
			elsif ($opts =~ /[\&]/)
			{
				$self->{'DATA'}->{$datum} .= shift;
			}
			else
			{
				push @{ $self->{'DATA'}->{$datum} }, @_;
			}
		}
		elsif ($method eq 'set')
		{
			if ($opts =~ /[1\?\&]/)
			{
				$self->{'DATA'}->{$datum} = shift;
			}
			else
			{
				$self->{'DATA'}->{$datum} = \@_;
			}
		}
	}
}

1;

