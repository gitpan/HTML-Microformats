=head1 NAME

HTML::Microformats::Format::hCard::impp - helper for hCards; handles the impp property

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

package HTML::Microformats::Format::hCard::impp;

use base qw(HTML::Microformats::Format::hCard::TypedField);
use common::sense;
use 5.008;

our $VERSION = '0.101';


1;
