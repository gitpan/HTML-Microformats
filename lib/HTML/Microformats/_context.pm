=head1 NAME

HTML::Microformats::_context - context for microformat objects

=head1 DESCRIPTION

Microformat objects need context when being parsed to properly make sense.
For example, a base URI is needed to resolve relative URI references, and a full
copy of the DOM tree is needed to implement the include pattern.

=cut

package HTML::Microformats::_context;

use common::sense;
use 5.008;

use HTML::Microformats::_cache;
use URI;
use XML::LibXML qw(:all);

=head2 Constructor

=over 4

=item C<< $context = HTML::Microformats::_context->new($dom, $baseuri) >>

Creates a new context from a DOM document and a base URI.

$dom will be modified, so if you care about keeping it pristine, make a clone first.

=back

=cut

sub new
{
	my ($class, $document, $uri, $cache) = @_;
	
	$cache ||= HTML::Microformats::_cache->new;
	
	my $self = {
		'document' => $document ,
		'uri'      => $uri ,
		'profiles' => [] ,
		'cache'    => $cache ,
		};
	bless $self, $class;
	
	foreach my $e ($document->getElementsByTagName('*'))
	{
		$e->setAttribute('data-cpan-html-microformats-nodepath', $e->nodePath)
	}

	$self->_process_langs($document->documentElement);
	$self->_detect_profiles;
	
	return $self;
}

=head2 Public Methods

=over 4

=item C<< $context->cache >>

A Microformat cache for the context. This prevents the same microformat object from
being parsed and reparsed - e.g. an adr parsed first in its own right, and later as a child
of an hCard.

=cut

sub cache
{
	return $_[0]->{'cache'};
}


=item C<< $context->document >>

Return the modified DOM document.

=cut

sub document
{
	return $_[0]->{'document'};
}

=item C<< $context->uri( [$relative_reference] ) >>

Called without a parameter, returns the context's base URI.

Called with a parameter, resolves the URI reference relative to the base URI.

=cut

sub uri
{
	my $this  = shift;
	my $param = shift || '';
	my $opts  = shift || {};
	
	if ((ref $opts) =~ /^XML::LibXML/)
	{
		my $x = {'element' => $opts};
		$opts = $x;
	}
	
	if ($param =~ /^([a-z][a-z0-9\+\.\-]*)\:/i)
	{
		# seems to be an absolute URI, so can safely return "as is".
		return $param;
	}
	elsif ($opts->{'require-absolute'})
	{
		return undef;
	}
	
	my $base = $this->{'uri'};
	if ($opts->{'element'})
	{
		$base = $this->get_node_base($opts->{'element'});
	}
	
	my $rv = URI->new_abs($param, $base)->canonical->as_string;

	while ($rv =~ m!^(http://.*)(\.\./|\.)+(\.\.|\.)?$!i)
	{
		$rv = $1;
	}
	
	return $rv;
}

=item C<< $context->make_bnode( [$element] ) >>

Mint a blank node identifier or a URI.

If an element is passed, this may be used to construct a URI in some way.

=cut

sub make_bnode
{
	my ($self, $elem) = @_;
	
	if (defined $elem && $elem->hasAttribute('id'))
	{
		my $uri = $self->uri('#' . $elem->getAttribute('id'));
		return 'http://thing-described-by.org/?'.$uri;
	}
	
	return '_:gen' . int(rand(100000));
}

=item C<< $context->profiles >>

A list of profile URIs declared by the document.

=cut

sub profiles
{
	return @{ $_[0]->{'profiles'} };
}

=item C<< $context->has_profile(@profiles) >>

Returns true iff any of the profiles in the array are declared by the document.

=cut

sub has_profile
{
	my $self = shift;
	foreach my $requested (@_)
	{
		foreach my $available ($self->profiles)
		{
			return 1 if $available eq $requested;
		}
	}
	return 0;
}

=item C<< $context->add_profile(@profiles) >>

Declare these additional profiles.

=cut

sub add_profile
{
	my $self = shift;
	foreach my $p (@_)
	{
		push @{ $self->{'profiles'} }, $p
			unless $self->has_profile($p);
	}
}

sub _process_langs
{
	my $self = shift;
	my $elem = shift;
	my $lang = shift;

	if ($elem->hasAttributeNS(XML_XML_NS, 'lang'))
	{
		$lang = $elem->getAttributeNS(XML_XML_NS, 'lang');
	}
	elsif ($elem->hasAttribute('lang'))
	{
		$lang = $elem->getAttribute('lang');
	}

	$elem->setAttribute('data-cpan-html-microformats-lang', $lang);	

	foreach my $child ($elem->getChildrenByTagName('*'))
	{
		$self->_process_langs($child, $lang);
	}
}

sub _detect_profiles
{
	my $self = shift;
	
	foreach my $head ($self->document->getElementsByTagNameNS('http://www.w3.org/1999/xhtml', 'head'))
	{
		if ($head->hasAttribute('profile'))
		{
			my @p = split /\s+/, $head->getAttribute('profile');
			foreach my $p (@p)
			{
				$self->add_profile($p) if length $p;
			}
		}
	}
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

Copyright 2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
