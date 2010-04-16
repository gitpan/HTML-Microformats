package HTML::Microformats::hCard::email;

use base qw(HTML::Microformats::hCard::_vt);
use common::sense;
use 5.008;


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
