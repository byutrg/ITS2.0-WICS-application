# Test correct functionality of the WICS modules
use strict;
use warnings;
use ITS::WICS qw(xml2html xliff2html reduceHtml xml2xliff);
use Test::More 0.88;
use FindBin '$Bin';
use Path::Tiny;
use Data::Section::Simple qw(get_data_section);
use Test::HTML::Differences;
use Test::XML;
plan tests => 5;

my $all = get_data_section;

#convert each type of document and test the output
my $html_path = path($Bin, qw(ITS-Reduce corpus test_param.html));
my $html = \(reduceHtml($html_path)->string);
normalize($html);
normalize(\$all->{reduceHtml_output});
eq_or_diff_html($$html, $all->{reduceHtml_output}, 'htmlReduce');

my $xml = $all->{xml2html_input};
$html = \(xml2html(\$xml)->string);
normalize($html);
normalize(\$all->{xml2html_output});
eq_or_diff_html($$html, $all->{xml2html_output}, 'xml2html');

my $xliff = $all->{xliff2html_input};
$html = \(xliff2html(\$xliff)->string);
normalize($html);
normalize(\$all->{xliff2html_output});
eq_or_diff_html($$html, $all->{xliff2html_output}, 'xliff2html');

$xliff = $all->{'xliff2html-labels_input'};
$html = \(xliff2html(\$xliff, 1)->string);
normalize($html);
normalize(\$all->{'xliff2html-labels_output'});
eq_or_diff_html($$html,
    $all->{'xliff2html-labels_output'}, 'xliff2html with labels');

$xml = $all->{xml2xliff_input};
$xliff = \(xml2xliff(\$xml)->string);
normalize($xliff);
normalize(\$all->{xml2xliff_output});
is_xml($$xliff, $all->{xml2xliff_output}, 'xml2xliff');

#pre-process HTML to make comparing scripts easier
sub normalize {
  my ($html) = @_;

  #normalize to make processing scripts easier
  $$html =~ s/\n\s*\n/\n/g;
  $$html =~ s/ +/ /g;
  $$html =~ s/^ //gm;
  return;
}

__DATA__
@@ xml2html_input
<xml/>
@@ xml2html_output
<!DOCTYPE html>
    <meta charset="utf-8">
    <title>WICS</title>
    <script type="application/its+xml">
      <its:rules xmlns:its="http://www.w3.org/2005/11/its" xmlns:h="http://www.w3.org/1999/xhtml" version="2.0">
        <its:localeFilterRule localeFilterList="*" selector="//@*" localeFilterType="include"/>
        <its:dirRule selector="//@*" dir="ltr"/>
        <its:translateRule selector="//@*" translate="no"/>
        <its:withinTextRule selector="//h:span" withinText="no"/>
      </its:rules>
    </script>
  <div title="xml"></div>

@@ xliff2html_input
<xliff/>
@@ xliff2html_output
<!DOCTYPE html>
    <meta charset="utf-8">
    <title>WICS</title>
    <script type="application/its+xml">
      <its:rules xmlns:its="http://www.w3.org/2005/11/its" xmlns:h="http://www.w3.org/1999/xhtml" version="2.0">
        <its:localeFilterRule localeFilterList="*" selector="//@*" localeFilterType="include"/>
        <its:dirRule selector="//@*" dir="ltr"/>
        <its:translateRule selector="//@*" translate="no"/>
        <its:targetPointerRule selector="//*[@title='source']" targetPointer="../*[@title='target']"/>
      </its:rules>
    </script>
    <style>body {visibility:hidden} p {visibility: visible}</style>
  <div title="xliff"></div>

@@ xliff2html-labels_input
<xliff xmlns="urn:oasis:names:tc:xliff:document:1.2">
  <trans-unit>
    <source>foo</source>
    <target></target>
  </trans-unit>
</xliff>
@@ xliff2html-labels_output
<!DOCTYPE html>
    <meta charset="utf-8">
    <title>WICS</title>
    <script type="application/its+xml">
      <its:rules xmlns:its="http://www.w3.org/2005/11/its" xmlns:h="http://www.w3.org/1999/xhtml" version="2.0">
        <its:localeFilterRule localeFilterList="*" selector="//@*" localeFilterType="include"/>
        <its:dirRule selector="//@*" dir="ltr"/>
        <its:translateRule selector="//@*" translate="no"/>
        <its:dirRule selector="id('ITS_1')" dir="ltr"/>
        <its:localeFilterRule localeFilterList="*" selector="id('ITS_1')" localeFilterType="include"/>
        <its:translateRule selector="id('ITS_1')" translate="no"/>
        <its:targetPointerRule selector="//*[@title='source']" targetPointer="../*[@title='target']"/>
      </its:rules>
    </script>
    <style>body {visibility:hidden} p {visibility: visible}</style>
    <div title="xliff">
      <div title="trans-unit">
        <p class="ITS_LABEL ITS_EMPTY_TARGET" id="ITS_1">Target is empty</p>
        <p title="source">foo</p>
        <p title="target"></p>
      </div>
    </div>

@@ xml2xliff_input
<xml/>
@@ xml2xliff_output
<?xml version="1.0" encoding="utf-8"?>
<xliff
    xmlns="urn:oasis:names:tc:xliff:document:1.2"
    xmlns:its="http://www.w3.org/2005/11/its"
    xmlns:itsxlf="http://www.w3.org/ns/its-xliff/"
    its:version="2.0">
  <file original="STRING" source-language="en" datatype="plaintext">
    <body></body>
  </file>
</xliff>

@@ reduceHtml_output
<!DOCTYPE html>
  <head>
    <title>WICS</title>
    <meta charset="utf-8">
    <script type="application/its+xml" id="lq1">
      <its:locQualityIssues xml:id="lq1" xmlns:its="http://www.w3.org/2005/11/its">
        <its:locQualityIssue
          locQualityIssueType="misspelling"
          locQualityIssueComment="'c'es' is unknown. Could be 'c'est'"
          locQualityIssueSeverity="50"/>
      </its:locQualityIssues>
    </script>
    <script id="ext1container" type="application/its+xml">
      <its:rules xmlns:its="http://www.w3.org/2005/11/its" xml:id="ext1container" version="2.0">
        <its:param name="title">Text</its:param>
        <its:param name="trmarkId">notran</its:param>
        <its:param name="foo">bar2</its:param>
        <its:param name="baz">qux</its:param>
      <!-- param 'foo' will override one from calling file -->
      <its:translateRule xml:id="ext_rule" selector="//*[@baz=$baz]" translate="yes"/>
</its:rules>
    </script>
    <script id="ext2container" type="application/its+xml">
      <its:rules xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:its="http://www.w3.org/2005/11/its" xml:id="ext2container" version="2.0" xlink:type="simple" xlink:href="external_param.xml">
        <its:param name="title">Text</its:param>
        <its:param name="trmarkId">notran</its:param>
        <its:param name="foo">bar1</its:param>
      </its:rules>
    </script>
    <script id="baseFileContainer" type="application/its+xml">
      <its:rules xmlns:its="http://www.w3.org/2005/11/its" xmlns:h="http://www.w3.org/1999/xhtml" xml:id="baseFileContainer" version="2.0">
        <its:param name="title">Text</its:param>
        <its:param name="trmarkId">notran</its:param>
        <its:param name="foo">bar1</its:param>
           <its:idValueRule xml:id="idValRule" selector="id($title)" idValue="bodyId"/>
           <its:locNoteRule xml:id="locNoteRule" selector="id($title)" locNotePointer="id($trmarkId)"/>
          </its:rules>
    </script>
  </head>
  <body>
    <p id="InvalidParameter">
      Invalid parameter
    </p>
  </body>
