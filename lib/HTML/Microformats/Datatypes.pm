package HTML::Microformats::Datatypes;

use HTML::Microformats::Datatypes::DateTime;
use HTML::Microformats::Datatypes::Duration;
use HTML::Microformats::Datatypes::Interval;
use HTML::Microformats::Datatypes::RecurringDateTime;
use HTML::Microformats::Datatypes::String;

our $VERSION = '0.00_12';

1;

__END__

=head1 NAME

HTML::Microformats::Datatypes - representations of literal values

=head1 DESCRIPTION

Many places you'd expect a Perl scalar to appear, e.g.:

  $my_hcard->get_fn;

What you actually get returned is an object from one of the Datatypes
modules. Why? Because using a scalar loses information. For example,
most strings have associated language information (from HTML lang and
xml:lang attributes). Using an object allows this information to be kept.

The Datatypes modules overload stringification, which means that for
the most part, you can use them as strings (subjecting them to
regular expressions, concatenating them, printing them, etc) and
everything will work just fine. But they're not strings.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats>.

L<HTML::Microformats::Datatypes::DateTime>,
L<HTML::Microformats::Datatypes::Duration>,
L<HTML::Microformats::Datatypes::Interval>,
L<HTML::Microformats::Datatypes::String>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
