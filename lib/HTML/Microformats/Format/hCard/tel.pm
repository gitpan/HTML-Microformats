=head1 NAME

HTML::Microformats::Format::hCard::tel - helper for hCards; handles the tel property

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

package HTML::Microformats::Format::hCard::tel;

use base qw(HTML::Microformats::Format::hCard::TypedField);
use common::sense;
use 5.008;

our $VERSION = '0.101';

sub _fix_value_uri
{
	my $self  = shift;
	my $uri;

	return if $self->{'DATA'}->{'value'} =~ /^(tel|modem|fax):\S+$/i;
	
	my $number = $self->{'DATA'}->{'value'};
	$number =~ s/[^\+\*\#x0-9]//gi;
	($number, my $extension) = split /x/i, $number, 2;
	
	if ($number =~ /^\+/) # global number
	{
		return if $number =~ /[\*\#]/;  # cannot contain * or #
		
		if (length $extension)
		{
			$uri = sprintf('tel:%s;extension=%s', $number, $extension);
		}
		else
		{
			$uri = sprintf('tel:%s', $number);
		}
	}
	else #local number
	{
		if (length $extension)
		{
			$uri = sprintf('tel:%s;extension=%s;phone-context=localhost.localdomain', $number, $extension);
		}
		else
		{
			$uri = sprintf('tel:%s;phone-context=localhost.localdomain', $number);
		}
	}
	
	$self->{'DATA'}->{'value'} = $uri;
}

1;
