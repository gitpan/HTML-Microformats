=head1 NAME

HTML::Microformats::ObjectCache - cache for microformat objects

=head1 DESCRIPTION

Prevents microformats from being parsed twice within the same context.

This is not just for saving time. It also prevents the occasional infinite loop, and
makes sure identifiers are used consistently.

=cut

package HTML::Microformats::ObjectCache;

use common::sense;
use 5.008;

our $VERSION = '0.100';

=head2 Constructor

=over 4

=item C<< $cache = HTML::Microformats::ObjectCache->new >>

Creates a new, empty cache.

=back

=cut

sub new
{
	my $class = shift;
	my $self  = bless {}, $class;
	return $self;
}

=head2 Public Methods

=over 4

=item C<< $cache->set($context, $package, $element, $object);

For a given context, package (e.g. 'HTML::Microformats::Format::hCard') and DOM
element node, stores an object in the cache.

=cut

sub set
{
	my $self  = shift;
	my $ctx   = shift;
	my $elem  = shift;
	my $klass = shift;
	my $obj   = shift;
	
	my $nodepath = $elem->getAttribute('data-cpan-html-microformats-nodepath');
	
	$self->{ $ctx->uri }->{ $klass }->{ $nodepath } = $obj;
	
	return $self->{ $ctx->uri }->{ $klass }->{ $nodepath };
}

=item C<< $object = $cache->get($context, $package, $element);

For a given context, package (e.g. 'HTML::Microformats::Format::hCard') and DOM
element node, retrieves an object from the cache.

=cut

sub get
{
	my $self  = shift;
	my $ctx   = shift;
	my $elem  = shift;
	my $klass = shift;
	
	my $nodepath = $elem->getAttribute('data-cpan-html-microformats-nodepath');

#	print sprintf("Cache %s on %s for %s.\n",
#		($self->{ $ctx->uri }->{ $klass }->{ $nodepath } ? 'HIT' : 'miss'),
#		$nodepath, $klass);

	return $self->{ $ctx->uri }->{ $klass }->{ $nodepath };
}

=item C<< @objects = $cache->get_all($context, [$package]);

For a given context and package (e.g. 'HTML::Microformats::Format::hCard'), retrieves a
list of objects from within the cache.

=back

=cut

sub get_all
{
	my $self  = shift;
	my $ctx   = shift;
	my $klass = shift || undef;
	
	if (defined $klass)
	{
		return values %{ $self->{$ctx->uri}->{$klass} };
	}

	my @rv;
	foreach my $klass ( keys %{ $self->{$ctx->uri} } )
	{
		push @rv, (values %{ $self->{$ctx->uri}->{$klass} });
	}
	return @rv;
}

1;

__END__

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
