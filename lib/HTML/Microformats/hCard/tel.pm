package HTML::Microformats::hCard::tel;

use base qw(HTML::Microformats::hCard::_vt);
use common::sense;
use 5.008;

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
