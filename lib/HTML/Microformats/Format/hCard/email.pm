=head1 NAME

HTML::Microformats::Format::hCard::email - helper for hCards; handles the email property

=head1 DESCRIPTION

Technically, this inherits from HTML::Microformats::Format::hCard::TypedField, so can be used in the
same way as any of the other microformat module, though I don't know why you'd
want to.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats>,
L<HTML::Microformats::Format::hCard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

package HTML::Microformats::Format::hCard::email;

use base qw(HTML::Microformats::Format::hCard::TypedField);
use common::sense;
use 5.008;

our $VERSION = '0.101';

sub _fix_value_uri
{
	my $self  = shift;

	return if $self->{'DATA'}->{'value'} =~ /^(mailto):\S+\@\S+$/i;
	
	# I only know how to fix SMTP addresses...
	return unless $self->{'DATA'}->{'value'} =~ /.+\@.+/i;
	
	my $email = $self->{'DATA'}->{'value'};
	$email =~ s/\s//g;
	$email = "mailto:$email" unless $email =~ /^mailto:/i;
	
	$self->{'DATA'}->{'value'} = $email;
}

1;
