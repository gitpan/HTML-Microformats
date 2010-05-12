=head1 NAME

HTML::Microformats::RELBASE - base rel-* microformat class

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

HTML::Microformats::RELBASE inherits from HTML::Microformats::BASE. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=head2 Additional Methods

=over 4

=item C<< $relfoo->get_href() >>

Returns the absolute URL of the resource being linked to.

=item C<< $relfoo->get_label() >>

Returns the linked text of the E<lt>aE<gt> element. Microformats patterns
like value excerpting are used.

=item C<< $relfoo->get_title() >>

Returns the contents of the title attribute of the E<lt>aE<gt> element,
or the same as C<< $relfoo->get_label() >> if the attribute is not set.

=back

=cut

package HTML::Microformats::RELBASE;

use base qw(HTML::Microformats::BASE);
use common::sense;
use 5.008;

use HTML::Microformats::_util qw(stringify);

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
	
	$self->{'DATA'}->{'href'} = $context->uri( $element->getAttribute('href') );
	$self->{'DATA'}->{'label'}   = stringify($element, 'value');
	$self->{'DATA'}->{'title'}   = $element->hasAttribute('title')
	                             ? $element->getAttribute('title')
	                             : $self->{'DATA'}->{'label'};
	
	$cache->set($context, $element, $class, $self)
		if defined $cache;
	
	return $self;
}

1;

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::BASE>,
L<HTML::Microformats>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

