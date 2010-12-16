use strict;
use warnings;

use inc::Module::Install;

my $dist = 'HTML-Microformats';
my $fn   = "lib/$dist.pm"; $fn =~ s#-#/#g;

name                $dist;
perl_version_from   $fn;
version_from        $fn;
abstract_from       $fn;
readme_from         $fn;
author              'Toby Inkster <tobyink@cpan.org>';
license             'perl';

test_requires       'Test::More'          => '0.61';
test_requires       'Module::Signature'   => '0.66';

requires            'Carp'                => '1.00';
requires            'CGI'                 => 0;
requires            'CGI::Util'           => 0;
requires            'common::sense'       => 0;
requires            'DateTime'            => 0;
requires            'DateTime::Duration'  => 0;
requires            'DateTime::Format::Builder'  => 0;
requires            'DateTime::Format::Natural'  => 0;
requires            'DateTime::Format::Strptime' => 0;
requires            'DateTime::Span'      => 0;
requires            'HTML::HTML5::Parser' => 0;
requires            'HTML::HTML5::Sanity' => 0;
requires            'HTTP::Date'          => 0;
requires            'JSON'                => 0;
requires            'Locale::Country'     => 0;
requires            'Module::Pluggable'   => 0;
requires            'RDF::Trine'          => '0.130';
requires            'XML::LibXML'         => '1.60';
requires            'URI'                 => '1.30';
requires            'URI::URL'            => 0;

resources(
	'homepage'   => "http://search.cpan.org/dist/$dist/",
	'repository' => "http://goddamn.co.uk/viewvc/perlmods/$dist/",
	'bugtracker' => "http://rt.cpan.org/Dist/Display.html?Queue=$dist",
	);

keywords('XHTML', 'HTML', 'Semantic Web', 'Microformats', 'POSH', 'RDF', 'JSON');
	
write_doap_changes;
write_doap_changes_xml;

include 'Test::Signature';
auto_install;
WriteAll(
	'meta' => 1,
	'sign' => 1,
	);
