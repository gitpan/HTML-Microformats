=head1 NAME

HTML::Microformats::Format::hCard::n - helper for hCards; handles the n property

=head1 DESCRIPTION

Technically, this inherits from HTML::Microformats::Format, so can be used in the
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

=cut

package HTML::Microformats::Format::hCard::n;

use base qw(HTML::Microformats::Format HTML::Microformats::Mixin::Parser);
use common::sense;
use 5.008;

use HTML::Microformats::Format::hCard;

our $VERSION = '0.102';

sub new
{
	my ($class, $element, $context) = @_;
	my $cache = $context->cache;
	
	my $self = {
		'element'    => $element ,
		'context'    => $context ,
		'cache'      => $cache ,
		'id'         => $context->make_bnode($element) ,
		};	
	bless $self, $class;

	my $clone = $element->cloneNode(1);	
	$self->_expand_patterns($clone);
	$self->_simple_parse($clone);
	
	return $self;
}

sub format_signature
{
	my $self  = shift;
	my $vcard = 'http://www.w3.org/2006/vcard/ns#';
	my $vx    = 'http://buzzword.org.uk/rdf/vcardx#';

	return {
		'root' => 'n',
		'classes' => [
			['additional-name',  '*'],
			['family-name',      '*'],
			['given-name',       '*'],
			['honorific-prefix', '*'],
			['honorific-suffix', '*'],
			['initial',          '*'], # extension
		],
		'options' => {
			'no-destroy' => ['adr', 'geo']
		},
		'rdf:type' => ["${vcard}Name"] ,
		'rdf:property' => {
			'additional-name'   => { 'literal' => ["${vcard}additional-name"] } ,
			'family-name'       => { 'literal' => ["${vcard}family-name"] } ,
			'given-name'        => { 'literal' => ["${vcard}given-name"] } ,
			'honorific-prefix'  => { 'literal' => ["${vcard}honorific-prefix"] } ,
			'honorific-suffix'  => { 'literal' => ["${vcard}honorific-suffix"] } ,
			'honorific-initial' => { 'literal' => ["${vx}initial"] } ,
		},
	};
}

sub profiles
{
	return HTML::Microformats::Format::hCard::profiles(@_);
}

1;
