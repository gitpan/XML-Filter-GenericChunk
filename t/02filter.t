use Test;
BEGIN { plan tests => 11 }
END { ok(0) unless $loaded }

use XML::LibXML;
use XML::LibXML::SAX::Parser;
use XML::LibXML::SAX::Builder;

use XML::Filter::CharacterChunk;
$loaded = 1;

use strict;
use warnings;

ok(1);

my $string = "<a>&lt;foo/&gt;foo&lt;foo&gt;bar&lt;/foo&gt;</a>";
my $tstr   = "<foo/>foo<foo>bar</foo>";
my $value  = "foobar";

my $p = XML::LibXML->new();

my $doc = $p->parse_string( $string );

my $handler   = XML::LibXML::SAX::Builder->new();
my $filter    = XML::Filter::CharacterChunk->new(Handler=>$handler);
my $generator = XML::LibXML::SAX::Parser->new(Handler=>$filter);

$filter->set_tagname( "a" );
my $dom = $generator->generate( $doc );
my $root = $dom->documentElement();
ok( $root->string_value(), $value );


$filter->set_namespace( "foo" );

# now the first string should not be processed

$dom = $generator->generate( $doc );
$root = $dom->documentElement();
ok( $root->toString(), $string );

my $nsstr = '<a><x:a xmlns:x="foo">&lt;foo/&gt;foo&lt;foo&gt;bar&lt;/foo&gt;</x:a></a>';
$doc = $p->parse_string( $nsstr );
$dom = $generator->generate( $doc );
( $root ) = $dom->findnodes("/a/*[local-name() = 'a']");
ok( $root->string_value(), $value );

$filter->relaxed_names(1);

$dom = $generator->generate( $doc );
( $root ) = $dom->findnodes("/a/*[local-name() = 'a']"); 
ok( $root->string_value(), $value );

# now the first string should be processed again
$doc = $p->parse_string( $string );
$dom = $generator->generate( $doc );
$root = $dom->documentElement();
ok( $root->string_value(), $value );

# ok this has to be tested as well
$filter->relaxed_names(0);
$filter->set_namespace("");

my $complex = q{
<bar>
<b>foo</b>
<a>&lt;foo/&gt;foo&lt;foo&gt;bar&lt;/foo&gt;</a>
<c>&lt;foo/&gt;bar&lt;foo&gt;foo&lt;/foo&gt;</c>
</bar>
};

$doc = $p->parse_string( $complex );
$dom = $generator->generate( $doc );
my ( $a ) = $dom->findnodes( "//a" );
my ( $c ) = $dom->findnodes( "//c" );
ok( $a->string_value, $value );
ok( $c->string_value, "<foo/>bar<foo>foo</foo>" );

# ok test if more tag names won't cause confusion
$filter->set_tagname(qw( a c ));

$dom = $generator->generate( $doc );
( $a ) = $dom->findnodes( "//a" );
( $c ) = $dom->findnodes( "//c" );
ok( $a->string_value, $value );
ok( $c->string_value, "barfoo" );

# warn $dom->toString;

my $filter2 = XML::Filter::CharacterChunk->new(Encoding=>"ISO-8859-1",
                                               Handler=>$handler,
                                               TagName=>["a"] );

$filter2->start_document();
$filter2->start_element({Name=>"a", LocalName=>"a", Prefix=>""});
$filter2->characters( {Data=>"<foo/>bär<foo>föo</foo>"} );
$filter2->end_element({Name=>"a", LocalName=>"a", Prefix=>""});
$dom = $filter2->end_document();


( $a ) = $dom->findnodes( "//a" );
#( $c ) = $dom->findnodes( "//c" );
ok( $a->string_value, encodeToUTF8("ISO-8859-1","bärföo") );
#ok( $c->string_value, "barfoo" );

# warn $dom->toString;
