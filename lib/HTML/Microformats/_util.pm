package HTML::Microformats::_util;

use base qw(Exporter);
use common::sense;
use utf8;
use 5.008;

use HTML::Microformats::Datatypes::String;
use XML::LibXML qw(:all);

our @EXPORT_OK = qw(searchClass searchAncestorClass searchRel searchID stringify xml_stringify);

sub searchClass
{
	my $target = shift;
	my $dom    = shift;
	my $prefix = shift || undef;
	
	my @matches;
	return @matches unless $dom;
	
	foreach my $node ($dom->getElementsByTagName('*'))
	{
		my $classList;
		$classList = $node->getAttribute('class');
		$classList = $node->getAttribute('name')
			if (!length $classList) && ($node->tagName eq 'param');
		
		next unless length $classList;
		
		if ((defined $prefix) && $classList =~ / (^|\s) ($prefix \-?)? $target (\s|$) /x)
		{
			push @matches, $node;
		}
		elsif ($classList =~ / (^|\s) $target (\s|$) /x)
		{
			push @matches, $node;
		}
	}
	
	return @matches;	
}

sub searchAncestorClass
{
	my $target = shift;
	my $dom    = shift;
	my $skip   = shift;
	
	if ($skip <= 0)
	{
		my $classList;
		$classList = $dom->getAttribute('class');
		$classList = $dom->getAttribute('name')
			if (!length $classList and $dom->tagName eq 'param');
		
		if ($classList =~ / (^|\s) $target (\s|$) /x)
		{
			return $dom;
		}
	}
	
	if (defined $dom->parentNode
	and $dom->parentNode->isa('XML::LibXML::Element'))
	{
		return searchAncestorClass($target, $dom->parentNode, $skip-1);
	}
	
	return undef;
}

sub searchRel
{
	my $target = shift;
	my $dom    = shift;
	
	$target =~ s/[\:\.]/\[\:\.\]/;
	
	my @matches = ();
	for my $node ($dom->getElementsByTagName('*'))
	{
		my $classList = $node->getAttribute('rel');
		next unless (length $classList);
		
		if ($classList =~ / (^|\s) $target (\s|$) /ix)
		{
			push @matches, $node;
		}
	}
	
	return @matches;
	
}

sub searchID
{
	my $target = shift;
	my $dom    = shift;
	
	$target =~ s/^\#//;
	
	my @matches = ();
	for my $node ($dom->getElementsByTagName('*'))
	{
		my $id   = $node->getAttribute('id') || next;
		
		if ($id eq $target)
		{
			return $node;
		}
	}	
}

# This function takes on too much responsibility.
# It should delegate stuff.
sub stringify
{
	my $dom        = shift;
	my $valueClass = shift || undef;
	my $doABBR     = shift || (length $valueClass);
	my $str;
	
	my %opts;
	
	if (ref($valueClass) eq 'HASH')
	{
		%opts = %$valueClass;
		
		$valueClass = $opts{'excerpt-class'};
		$doABBR     = $opts{'abbr-pattern'};
	}
	
	return unless ($dom);

	# value-title
	if ($opts{'value-title'} =~ /(allow|require)/i or
	($opts{'datetime'} && $opts{'value-title'} !~ /(forbid)/i))
	{
		KIDDY: foreach my $kid ($dom->childNodes)
		{
			next if $kid->nodeName eq '#text' && $kid->textContent !~ /\S/; # skip whitespace
			
			last # anything without class='value-title' and a title attribute causes us to bail out.
				unless
				$opts{'value-title'} =~ /(lax)/i
				|| ($kid->can('hasAttribute')
				&& $kid->hasAttribute('class')
				&& $kid->hasAttribute('title')
				&& $kid->getAttribute('class') =~ /\b(value\-title)\b/);
			
			my $str = $kid->getAttribute('title');
			utf8::encode($str);
			return HTML::Microformats::Datatypes::String::ms($str, $kid);
		}
	}
	return if $opts{'value-title'} =~ /(require)/i;

	# ABBR pattern
	if ($doABBR)
	{
		if ($dom->nodeType==XML_ELEMENT_NODE
			&& length $dom->getAttribute('data-cpan-html-microformats-content'))
		{
			my $title = $dom->getAttribute('data-cpan-html-microformats-content');
			return HTML::Microformats::Datatypes::String::ms($title, $dom);
		}
		elsif ( ($dom->nodeType==XML_ELEMENT_NODE 
			&& $dom->tagName eq 'abbr' 
			&& $dom->hasAttribute('title'))
		||   ($dom->nodeType==XML_ELEMENT_NODE 
			&& $dom->tagName eq 'acronym' 
			&& $dom->hasAttribute('title'))
		||   ($dom->nodeType==XML_ELEMENT_NODE
			&& $dom->getAttribute('title') =~ /data\:/)
		)
		{
			my $title = $dom->getAttribute('title');
			utf8::encode($title);
	
			if ($title =~ / [\(\[\{] data\: (.*) [\)\]\}] /x
			||  $title =~ / data\: (.*) $ /x )
				{ $title = $1; }
	
			if (defined $title)
				{ return (ms $title, $dom); }
		}
		elsif ($dom->nodeType==XML_ELEMENT_NODE 
			&& $opts{'datetime'} 
			&& $dom->hasAttribute('datetime'))
		{
			my $str = $dom->getAttribute('datetime');
			utf8::encode($str);
			return HTML::Microformats::Datatypes::String::ms($str, $dom);
		}
	}
	
	# Value excerpting.
	if (length $valueClass)
	{
		my @nodes = searchClass($valueClass, $dom);
		my @strs;
		if (@nodes)
		{
			foreach my $valueNode (@nodes)
			{
				push @strs, stringify($valueNode, {
					'excerpt-class'   => undef,
					'abbr-pattern'    => $doABBR,
					'datetime'        => $opts{'datetime'},
					'keep-whitespace' => 1
				});
			}
			
			# In datetime mode, be smart enough to detect when date, time and
			# timezone have been given in wrong order.
			if ($opts{'datetime'})
			{
				my $dt_things = {};
				foreach my $x (@strs)
				{
					if ($x =~ /^\s*(Z|[+-]\d{1,2}(\:?\d\d)?)\s*$/i)
						{ push @{$dt_things->{'z'}}, $1; }
					elsif ($x =~ /^\s*T?([\d\.\:]+)\s*$/i)
						{ push @{$dt_things->{'t'}}, $1; }
					elsif ($x =~ /^\s*([\d-]+)\s*$/i)
						{ push @{$dt_things->{'d'}}, $1; }
					elsif ($x =~ /^\s*T?([\d\.\:]+)\s*(Z|[+-]\d{1,2}(\:?\d\d)?)\s*$/i)
					{
						push @{$dt_things->{'t'}}, $1;
						push @{$dt_things->{'z'}}, $2;
					}
					elsif ($x =~ /^\s*([\d]+)(?:[:\.](\d+))(?:[:\.](\d+))?\s*([ap])\.?\s*[m]\.?\s*$/i)
					{
						my $h = $1;
						if (uc $4 eq 'P' && $h<12)
						{
							$h += 12;
						}
						elsif (uc $4 eq 'A' && $h==12)
						{
							$h = 0;
						}
						my $t = (defined $3) ? sprintf("%02d:%02d:%02d", $h, $2, $3) : sprintf("%02d:%02d", $h, $2);
						push @{$dt_things->{'t'}}, $t;
					}
				}
				
				if (defined $opts{'datetime-feedthrough'} && !defined $dt_things->{'d'}->[0])
				{
					push @{ $dt_things->{'d'} }, $opts{'datetime-feedthrough'}->ymd('-');
				}
				if (defined $opts{'datetime-feedthrough'} && !defined $dt_things->{'z'}->[0])
				{
					push @{ $dt_things->{'z'} }, $opts{'datetime-feedthrough'}->strftime('%z');
				}
				
				$str = sprintf("%s %s %s",
					$dt_things->{'d'}->[0],
					$dt_things->{'t'}->[0],
					$dt_things->{'z'}->[0]);
			}
			
			unless (length $str)
			{
				$str = HTML::Microformats::Datatypes::String::ms((join $opts{'joiner'}, @strs), $dom);
			}
		}
	}

	my $inpre = ($dom->getAttribute('_xpath') =~ /\/pre\b/i) ? 1 : 0; ##TODO - this doesn't work!
	eval {
		$str = _stringify_helper($dom, $inpre, 0)
			unless defined $str;
	};
	#$str = '***UTF-8 ERROR (WTF Happened?)***' if $@;
	#$str = '***UTF-8 ERROR (Not UTF-8)***' unless utf8::is_utf8("$str");
	#$str = '***UTF-8 ERROR (Bad UTF-8)***' unless utf8::valid("$str");
	
	if ($opts{'datetime'} && defined $opts{'datetime-feedthrough'})
	{
		if ($str =~ /^\s*T?([\d\.\:]+)\s*$/i)
		{
			$str = sprintf('%s %s %s',
				$opts{'datetime-feedthrough'}->ymd('-'),
				$1,
				$opts{'datetime-feedthrough'}->strftime('%z'),
				);
		}
		elsif ($str =~ /^\s*T?([\d\.\:]+)\s*(Z|[+-]\d{1,2}(\:?\d\d)?)\s*$/i)
		{
			$str = sprintf('%s %s %s',
				$opts{'datetime-feedthrough'}->ymd('-'),
				$1,
				$2,
				);
		}
		elsif ($str =~ /^\s*([\d]+)(?:[:\.](\d+))(?:[:\.](\d+))?\s*([ap])\.?\s*[m]\.?\s*$/i)
		{
			my $h = $1;
			if (uc $4 eq 'P' && $h<12)
			{
				$h += 12;
			}
			elsif (uc $4 eq 'A' && $h==12)
			{
				$h = 0;
			}
			my $t = (defined $3) ? sprintf("%02d:%02d:%02d", $h, $2, $3) : sprintf("%02d:%02d", $h, $2);
			$str = sprintf('%s %s %s',
				$opts{'datetime-feedthrough'}->ymd('-'),
				$t,
				$opts{'datetime-feedthrough'}->strftime('%z'),
				);
		}
	}

	unless ($opts{'keep-whitespace'})
	{
		# \x1D is used as a "soft" line break. It can be "absorbed" into an adjacent
		# "hard" line break.
		$str =~ s/\x1D+/\x1D/g;
		$str =~ s/\x1D\n/\n/gs;
		$str =~ s/\n\x1D/\n/gs;
		$str =~ s/\x1D/\n/gs;
		$str =~ s/(^\s+|\s+$)//gs;
	}
	
	return HTML::Microformats::Datatypes::String::ms($str, $dom);
}

sub _stringify_helper
{
	my $domNode   = shift || return;
	my $inPRE     = shift || 0;
	my $indent    = shift || 0;
	my $rv = '';

	my $tag;
	if ($domNode->nodeType == XML_ELEMENT_NODE)
	{
		$tag = lc($domNode->tagName);
	}
	elsif ($domNode->nodeType == XML_COMMENT_NODE)
	{
		return HTML::Microformats::Datatypes::String::ms('');
	}
	
	# Change behaviour within <pre>.
	$inPRE++ if $tag eq 'pre';
	
	# Text node, or equivalent.
	if (!$tag || $tag eq 'img' || $tag eq 'input' || $tag eq 'param')
	{
		$rv = $domNode->getData
			unless $tag;
		$rv = $domNode->getAttribute('alt')
			if $tag && $domNode->hasAttribute('alt');
		$rv = $domNode->getAttribute('value')
			if $tag && $domNode->hasAttribute('value');

		utf8::encode($rv);

		unless ($inPRE)
		{
			$rv =~ s/[\s\r\n]+/ /gs;
		}
		
		return $rv;
	}
	
	# Breaks.
	return "\n" if ($tag eq 'br');
	return "\x1D\n====\n\n"
		if ($tag eq 'hr');
	
	# Deleted text.
	return '' if ($tag eq 'del');

	# Get stringified children.
	my (@parts, @ctags, @cdoms);
	my $extra = 0;
	if ($tag =~ /^([oud]l|blockquote)$/)
	{
		$extra += 6; # Advisory for word wrapping.
	}
	foreach my $child ($domNode->getChildNodes)
	{
		my $ctag = $child->nodeType==XML_ELEMENT_NODE ? lc($child->tagName) : undef;
		my $str  = _stringify_helper($child, $inPRE, $indent + $extra);
		push @ctags, $ctag;
		push @parts, $str;
		push @cdoms, $child;
	}
	
	if ($tag eq 'ul' || $tag eq 'dir' || $tag eq 'menu')
	{
		$rv .= "\x1D";
		my $type = lc($domNode->getAttribute('type')) || 'disc';

		for (my $i=0; defined $parts[$i]; $i++)
		{
			next unless ($ctags[$i] eq 'li');
			
			$_ = $parts[$i];
			s/(^\x1D|\x1D$)//g;
			s/\x1D+/\x1D/g;
			s/\x1D\n/\n/gs;
			s/\n\x1D/\n/gs;
			s/\x1D/\n/gs;
			s/\n/\n    /gs;

			my $marker_type = $type;
			$marker_type = lc($cdoms[$i]->getAttribute('type'))
				if (length $cdoms[$i]->getAttribute('type'));

			my $marker = '*';
			if ($marker_type eq 'circle')    { $marker = '-'; }
			elsif ($marker_type eq 'square') { $marker = '+'; }
			
			$rv .= "  $marker $_\n";
		}
		$rv .= "\n";
	}
	
	elsif ($tag eq 'ol')
	{
		$rv .= "\x1D";
		
		my $count = 1;
		$count = $domNode->getAttribute('start')
			if (length $domNode->getAttribute('start'));
		my $type = $domNode->getAttribute('type') || '1';
		
		for (my $i=0; defined $parts[$i]; $i++)
		{
			next unless ($ctags[$i] eq 'li');
			
			$_ = $parts[$i];
			s/(^\x1D|\x1D$)//g;
			s/\x1D+/\x1D/g;
			s/\x1D\n/\n/gs;
			s/\n\x1D/\n/gs;
			s/\x1D/\n/gs;
			s/\n/\n    /gs;
			
			my $marker_value = $count;
			$marker_value = $cdoms[$i]->getAttribute('value')
				if (length $cdoms[$i]->getAttribute('value'));
			
			my $marker_type = $type;
			$marker_type = $cdoms[$i]->getAttribute('type')
				if (length $cdoms[$i]->getAttribute('type'));
				
			my $marker = sprintf('% 2d', $marker_value);
			if (uc($marker_type) eq 'A' && $marker_value > 0 && $marker_value <= 26)
				{ $marker = ' ' . chr( ord($marker_type) + $marker_value - 1 ); }
			elsif ($marker_type eq 'i' && $marker_value > 0 && $marker_value <= 3999)
				{ $marker = sprintf('% 2s', roman($marker_value)); }
			elsif ($marker_type eq 'I' && $marker_value > 0 && $marker_value <= 3999)
				{ $marker = sprintf('% 2s', Roman($marker_value)); }
				
			$rv .= sprintf("\%s. \%s\n", $marker, $_);

			$count++;
		}
		$rv .= "\n";
	}

	elsif ($tag eq 'dl')
	{
		$rv .= "\x1D";
		for (my $i=0; defined $parts[$i]; $i++)
		{
			next unless ($ctags[$i] eq 'dt' || $ctags[$i] eq 'dd');
			
			if ($ctags[$i] eq 'dt')
			{
				$rv .= $parts[$i] . ':';
				$rv =~ s/\:\s*\:$/\:/;
				$rv .= "\n";
			}
			elsif ($ctags[$i] eq 'dd')
			{
				$_ = $parts[$i];
				s/(^\x1D|\x1D$)//g;
				s/\x1D+/\x1D/g;
				s/\x1D\n/\n/gs;
				s/\n\x1D/\n/gs;
				s/\x1D/\n/gs;
				s/\n/\n    /gs;
				$rv .= sprintf("    \%s\n\n", $_);
			}
		}
	}

	elsif ($tag eq 'blockquote')
	{
		$rv .= "\x1D";
		for (my $i=0; defined $parts[$i]; $i++)
		{
			next unless ($ctags[$i]);
			
			$_ = $parts[$i];
			s/(^\x1D|\x1D$)//g;
			s/\x1D+/\x1D/g;
			s/\x1D\n/\n/gs;
			s/\n\x1D/\n/gs;
			s/\x1D/\n/gs;
			s/\n\n/\n/;
			s/\n/\n> /gs;
			$rv .= "> $_\n";
		}
		$rv =~ s/> $/\x1D/;
	}
	
	else
	{
		$rv = '';
		for (my $i=0; defined $parts[$i]; $i++)
		{
			$rv .= $parts[$i];
			
			# Hopefully this is a sensible algorithm for inserting whitespace
			# between childnodes. Needs a bit more testing though.
			
			# Don't insert whitespace if this tag or the next one is a block-level element.
			# Probably need to expand this list of block elements.
#			next if ($ctags[$i]   =~ /^(p|h[1-9]?|div|center|address|li|dd|dt|tr|caption|table)$/);
#			next if ($ctags[$i+1] =~ /^(p|h[1-9]?|div|center|address|li|dd|dt|tr|caption|table)$/);
			
			# Insert whitespace unless the string already ends in whitespace, or next
			# one begins with whitespace.
#			$rv .= ' '
#				unless ($rv =~ /\s$/ || (defined $parts[$i+1] && $parts[$i+1] =~ /^\s/));
		}
		
		if ($tag =~ /^(p|h[1-9]?|div|center|address|li|dd|dt|tr|caption|table)$/ && !$inPRE)
		{
			$rv =~ s/^[\t ]//s;
			#local($Text::Wrap::columns);
			#$Text::Wrap::columns = 78 - $indent;
			$rv = "\x1D".$rv;#Text::Wrap::wrap('','',$rv);
			if ($tag =~ /^(p|h[1-9]?|address)$/)
			{
				$rv .= "\n\n";
			}
		}
		
		if ($tag eq 'sub')
			{ $rv = "($rv)"; }
		elsif ($tag eq 'sup')
			{ $rv = "[$rv]"; }
		elsif ($tag eq 'q')
			{ $rv = "\"$rv\""; }
		elsif ($tag eq 'th' || $tag eq 'td')
			{ $rv = "$rv\t"; }
	}

	return $rv;
}


sub xml_stringify ##TODO
{
	my $node  = shift;
	my $clone = $node->cloneNode(1);
	
	foreach my $attr ($clone->attributes)
	{
		if ($attr->nodeName =~ /^data-cpan-html-microformats-/)
		{
			$clone->removeAttribute($attr->nodeName);
		}
	}
	foreach my $kid ($clone->getElementsByTagName('*'))
	{
		foreach my $attr ($kid->attributes)
		{
			if ($attr->nodeName =~ /^data-cpan-html-microformats-/)
			{
				$kid->removeAttribute($attr->nodeName);
			}
		}
	}
	
	return $clone->toString;
}

1;