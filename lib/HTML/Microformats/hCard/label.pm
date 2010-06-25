=head1 NAME

HTML::Microformats::hCard::label - helper for hCards; handles the label property

=head1 DESCRIPTION

Technically, this inherits from HTML::Microformats::hCard::_vt, so can be used in the
same way as any of the other microformat module, though I don't know why you'd
want to.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats>,
L<HTML::Microformats::hCard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

package HTML::Microformats::hCard::label;

use base qw(HTML::Microformats::hCard::_vt);
use common::sense;
use 5.008;

our $VERSION = '0.00_12';

1;

