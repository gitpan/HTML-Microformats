=head1 NAME

HTML::Microformats::VoteLinks - the VoteLinks microformat

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

HTML::Microformats::VoteLinks inherits from HTML::Microformats::RELBASE. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=head2 Additional Methods

=over 4

=item C<< $link->get_vote() >>

Returns the string 'for', 'against' or 'abstain'.

=item C<< $link->get_voter() >>

Returns the hCard of the person who authored the VoteLinks link, if it can
be determined from context. (It usually can't unless the page is also using
hAtom, and the hAtom on the page has already been parsed.)

=back

=cut

package HTML::Microformats::VoteLinks;

use base qw(HTML::Microformats::RELBASE);
use common::sense;
use 5.008;

use CGI::Util qw(unescape);

our $VERSION = '0.00_12';

sub new
{
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	
	my $rev = $self->element->getAttribute('rev');
	
	if ($rev =~ /\b(vote-for)\b/)
	{
		$self->{'DATA'}->{'vote'} = 'for';
	}
	if ($rev =~ /\b(vote-against)\b/)
	{
		return undef if $self->{'DATA'}->{'vote'} eq 'for';
		$self->{'DATA'}->{'vote'} = 'against';
	}
	if ($rev =~ /\b(vote-abstain)\b/)
	{
		return undef if $self->{'DATA'}->{'vote'} eq 'for';
		return undef if $self->{'DATA'}->{'vote'} eq 'against';
		$self->{'DATA'}->{'vote'} = 'abstain';
	}
	
	return $self;
}

sub format_signature
{
	my $v = 'http://rdf.opiumfield.com/vote/';
	
	return {
		'rev'      => ['vote-for', 'vote-abstain', 'vote-against'] ,
		'classes'  => [
				['href',     '1#'] ,
				['label',    '1#'] ,
				['title',    '1#'] ,
				['voter',    '*#'] ,
				['vote',     '1#'] ,
			] ,
		'rdf:type' => ["${v}VoteLink"] ,
		'rdf:property' => {
			'href'   => { resource => ["${v}voteResource"] } ,
			} ,
		}
}

sub profiles
{
	return qw(http://microformats.org/profile/votelinks
		http://ufs.cc/x/relvotelinks
		http://purl.org/uF/VoteLinks/1.0/
		http://tommorris.org/profiles/votelinks
		http://microformats.org/profile/specs
		http://ufs.cc/x/specs
		http://purl.org/uF/2008/03/);
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);
	
	my $v = 'http://rdf.opiumfield.com/vote/';
	
	foreach my $voter (@{ $self->data->{'voter'} })
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${v}voteBy"),
			$voter->id(1, 'holder'),
			));
	}

	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1),
		RDF::Trine::Node::Resource->new("${v}voted"),
		RDF::Trine::Node::Resource->new("${v}vote" . ucfirst lc $self->data->{'vote'}),
		));

	return $self;
}

1;


=head1 MICROFORMAT

HTML::Microformats::VoteLinks supports VoteLinks as described at
L<http://microformats.org/wiki/vote-links>.

=head1 RDF OUTPUT

Data is returned using the Tom Morris' vote vocabulary
(L<http://rdf.opiumfield.com/vote/>).

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::RELBASE>,
L<HTML::Microformats>,
L<HTML::Microformats::hAtom>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

