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

Copyright 2008-2011 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut

package HTML::Microformats::Format::hCard::impp;

use base qw(HTML::Microformats::Format::hCard::TypedField);
use common::sense;
use 5.010;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::hCard::impp::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::hCard::impp::VERSION   = '0.104';
}


1;
