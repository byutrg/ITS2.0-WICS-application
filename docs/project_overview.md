<a id="top"></a>
#WICS Converters Project report
Nathan Glenn <garfieldnate@gmail.com>

<a id="toc"></a>
##Table of Contents

1. [Overview](#overview)
2. [Approaches to Converting ITS-decorated XML](#approaches)
    1. [An Untried Approach](#untried)
3. [Working with XML/HTML](#working)
4. [Wrenches in ITS](#wrenches)
5. [Why HTML5?](#html5)
6. [ITS Community Discussions](#discussions)
7. [Bug Reports](#bugs)

<a id="overview"></a>
Four converters were produced for this project:

1. XML2HTML- convert ITS-decorated XML documents for browser display.
2. HTMLReduce- combine external ITS rules files referenced by an ITS-decorated HTML5 document into a single HTML5 document.
3. XLIFF2HTML- the same as `XML2HTML`, but converting only XLIFF documents, using XLIFF ITS, and displaying only `<source>` and `<target>` elements.
4. XML2XLIFF- extract translation units from an XML document and create a corresponding XLIFF file, with ITS intact. One sample file only.

The project required about 400 hours, spanning June to October 2013.

<a id="approaches"></a>
##Approaches to Converting ITS-decorated XML

Converting ITS-decorated XML to HTML is complicated. ITS information can annotate elements via local markup, global selection, or inheritance. Rules of inheritance and default values differ by ITS data category, and some are different in HTML, or are different depending on the type of element used in HTML (e.g. `translate`, as explained in 8.2.2 of the specification). All seven types of nodes (element, namespace, document, attribute, text, processing instruction and comment) can be be involved in annotation via relative selectors, since relative selectors can be anything (while absolute selectors, used for the `selector` values of rules, have to be either elements or attributes).

The goal for the HTML conversion was to output a valid HTML5 document containing the same text with the same ITS information as the input document.  Attributes would be placed in the document as text, since they are also annotated with ITS. Matching the structure of the HTML document with the XML document was not a requirement, but was a perk of the final implementation.

My first idea was extremely simple, but was didn't really fulfill the project goals. Because browsers handle unknown types of nodes and attributes robustly, the original XML document can simply be placed inside an HTML document. When it's rules are extracted, the selector XPaths could be applied with the original document root as the context node. This, however, would require changing any absolute XPaths (ones starting with `/`) to begin with the new path to the original root node, and might also break other XPath expressions (`//*[not(ancestor::body)]` or `/` come to mind). Besides this, the output document would not be using real ITS. It would be using XML ITS inside of an HTML document, which would (and did, for the demo) require a special processor. The project goal was something that could produce valid ITS-decorated HTML.

My next idea of how to convert XML to HTML was a very inflexible one. I figured I could convert every element and attribute to `<div>` or `<span>`, and then transform the XPath selectors in the global rules to match the document transformation. This is a bad idea for several reasons. First, XPath is a complete language, meaning it would require parsing. Second, the document transformations would require the XPath selectors to be changed in non-trivial ways. For example, simple indices (e.g. `//el[5]`) would need to be changed because new elements were being added to the document. It would actually be impossible to translate paths such as `//*[not(child::*)]`, because attributes were pasted as new children in the document.

My next idea was to get rid of the rules altogether, placing all ITS information into local markup (except where it already existed). This would make final document conversion simple, since creating an HTML ITS attribute out of an XML one is mostly very simple (attach `its-` and then uses dashes to separate words instead of camelCasing). However, closer inspection of the ITS spec showed me that not all data categories could be represented through a local attribute (there are also categories that can only be represented locally; I find this to be a handicap).

Finally Renat suggested I rewrite all of the rules, which worked pretty well. Here's a basic outline of the final algorithm:

1. Grab all ITS rules and store them in order of application.
2. Find all document matches and store them in an index.

    * each entry has a rule and it's matches- groups of one `selector` and one or more `pointer`s.

3. Transform document into HTML.

    * change elements to div or span.
    * convert ITS attributes to HTML versions.
    * store other attributes as new child elements.
    * put inside html structure (html, head, title, body).

4. Rewrite document rules to match the same nodes, as represented in the match index. Create one rule per match group.

5. Add new rules as needed to combat incorrect inheritance or other introduced discrpancies.

It is important to separate the "match" and "transform" steps because once the document is transformed, the XPaths contained in the document rules will no longer match.

The indexed nodes are saved as `FutureNodes`, which I use as a sort of promise that a node containing the original information will exist. This is needed for nodes that have to be deleted from the document. If a processing instruction (PI) is matched, the index remembers it's original location in the document, and then when queried later creates a new element containing the PI text in place of the original PI and returns that. I don't know why anyone would match a PI. Maybe the ITS spec was supposed to disallow this (.I never asked but probably should have.).

Step 5 corrects the ITS information inherited by newly created nodes. All attributes are placed as new elements in the document. Attributes don't inherit most ITS information, but elements do. Likewise, PIs and namespaces aren't normally annotated but are as elements. To fix this, new rules are created to reset the ITS information on these to sane defaults (like `translate="no"`). These rules are placed before all other rules in the document so that they have the lowest precedence and may be overridden by any rules provided by the user (There might be rules applying to attributes, but there won't be for the other types of nodes.).

Step 5 is also used to correct the default value of `withinText` for elements renamed to `span`. In HTML, the `<span>` element has a default `withinText` value of `yes`, but in XML all elements have a default value of `no`.

The shortcoming of this conversion approach is that not all ITS can be reset, and so some text is incorrectly annotated with ITS information. The ITS categories that inherit but do not have defaults are `langInfo`, `domain` and `provenance`. PIs and namespaces don't even have default ITS values, so setting default values on them is sane but not completely faithful to the original document. Attributes added to the document (`title` and `id`) also incorrectly inherit ITS information. This is only a loss in principle; I wanted to make the converter perfect, but it's not. I do not foresee this having any practical effect (marking a PI as being in English or a namespace as having been edited by Bob will not mean much to anyone).

The same basic algorithm is used in `XML2HTML` and `XLIFF2HTML`. `XML2XLIFF` is a little simpler because global rules do not need to be saved.

<a id="untried"><a>
###An Untried Approach

The approach that I did not try is completely rewriting the document from scratch. This would involve first resolving all ITS information for the entire document and then rewriting it so that all of the text inside of one element (and not nested inside of child elements) would be in its own element. These elements would each be placed in the document as a sibling so that no inheritance would occur. One would also need to wrap any elements with an `xml:id` attribute along with (elements created from) their children in a single element with the given id, so as to correctly preserve the information referenced by the `*Ref` attributes (`locNoteRef`, etc.).

The disadvantage of this approach is that the output would be nothing like the input. It could be completely incomprehensible to human eyes, and the relationship between an HTML element and its original XML element would be unclear. Furthermore, the relationship between ITS information and its annotated elements would be fragmented. For example, if a localization note were assigned on an element containing 50 children in the original document, the output HTML would have 50 separate elements with 50 separate localization notes. This could be troublesome if someone (user or programmer) ever wanted to ask the question "what element(s) does this localization note apply to?" To some extent this fragmentation also occurs in the current implementation, but only where global rules are involved (because they are copied). Finally, this would disallow the preservation of nested text flows (`withinText="nested"`).

This would of course also require an implementation of inheritance, which is not present in the `ITS` package currently.

<a id="working"></a>
## Working with XML

TODO

<a id="wrenches"><a>
## Wrenches in ITS

Occasionally there was something in the ITS specification that that threw a wrench in the engine-- the implementation seemed so nice and clean until I had to account for some exception. I'll list what I can think of here. These are not all necessarily desired changes to the spec, but might help future implementers.

1. Having categories that are local-only or global-only. Being able to localize all ITS attributes would have made the (XML|XLIFF)2HTML conversion almost trivial. Allowing implementors to only work with ITS attributes was a concern when creating the XLIFF ITS mapping, so it seems possible that it could be a concern for general XML ITS. It is certainly easier to implement attributes than global rules. Also, someone might find it convenient to be able to completely remove ITS metadata from an XML file and put it all in a separate `its:rules` document.

2. Since HTML5 already has a directionality attribute (`dir`), ITS uses that. The difficult thing here, though, is that a value of `lro` or `rlo` requires all children to be wrapped in a `<bdo>` element, which happens to be an inline element. All of the other local attributes can be deleted or converted into a different attribute, so this is a singular exception. Also, because `<bdo>` is an inline element, it complicated the logic needed to decide whether an element would be a `<div>` or a `<span>` (checking children for `<divs>` and parents for `<span>`s was now required).

3. Allowing relative selectors to be any kind of node. The complications caused by this were listed in the section on the conversion method.

4. Certain ITS markup in the XLIFF mapping requires wrapping the contents of `<source>` in a `<mrk>` element. This wasn't as bad as the other points, but still required some special thought.

<a id="html5"><a>
## Why HTML5?

In case your are curious, like I was, whether or not ITS can be used in earlier HTML versions, the answer is "no". ITS in HTML requires the use of `<its:rules>...</its:rules>` elements embedded in `<script type="application/its+xml">` elements. However, the first occurence of the sequence `</` (called `ETAGO`) signals the end of the script in earlier versions of HTML. Therefore, conformant HTML4 parsers will fail when trying to parse an ITS script element (see [here](http://mathiasbynens.be/notes/etago) for more information).

<a id="discussions"></a>
##Discussions in the ITS Community

This project required a very detailed understanding of the ITS 2.0 specification. There were times when a piece of information was missing from the specification, some of the language was ambiguous, or it was just difficult for me to understand. In some cases I wished there were a feature I needed. In these cases, I usually asked the ITS Interest Group via the public mailing list. Below are links to all of the discussions that I started, along with a summary of the question and answer. There are also discussions from the MultiLingual-LT Working Group mailing list, and GitHub issue discussions for the ITS 2.0 test suite.

A special thanks goes to the ITS IG members, MultiLingua-LT WG members and repository maintainers, who were very responsive and helpful during the entire project.

* [**XPath Context for Relative Selectors**](http://lists.w3.org/Archives/Public/public-i18n-its-ig/2013Jul/0035.html)

The spec states that the evaluation context for a relative selector is the same as for an absolute selector, with some exceptions. I was unsure if that meant that the description of the context would be the same or if the actual context was copied exactly (perhaps a bit nitpicky but you can never be too careful). I wanted to know which namespaces and which variables were in-scope for relative selectors, and the answer was that the same namespaces and variables that were available to the absolute selector are available to the current relative selector.

What it means is that the rule in the document below should not have any match for its `idValue`:

    <myDoc>
        <its:rules
          xmlns:its="http://www.w3.org/2005/11/its"
          version="2.0">
            <its:idValueRule selector="//par" idValue="string(bar:id)"/>
        </its:rules>
        <par xmlns:bar="www.bar.com">
            <bar:id>another loc note</bar:id>
        </par>
    </myDoc>

The reason for this is that though the `bar` namespace is in scope of the context node (`par`), it is not in the scope of the `its:idValueRule` element. This is not directly possible with XML::LibXML because it automatically registers namespaces in the scope of the context node and these namespaces cannot be unregistered. This currently constitutes a failing TODO test in the `ITS` module. See this [SO](http://stackoverflow.com/a/18944369/474819) for more information.


* [**XPath Context for idValue Evaluation**](http://lists.w3.org/Archives/Public/public-i18n-its-ig/2013Jul/0037.html)

The XPath context for relative selectors (used in `*Pointer` attributes) was specified in detail, and the text for the `idValue` attribute specified that it must be an XPath resulting in a literal string. However, the tests in the test suite used relative selectors to generate `idValue` strings. I asked what the XPath context is for `idValues`, and the IG members said that it was the same as for relative selectors and that the spec would be edited to indicate so. XPath context affects the result of the XPath `last` and `position` functions. Given this new information, we were able to test correct XPath context using this rule, which generates the ID's `par_1`, `par_2` etc. for all of the `<par>` elements in the document:

    <its:idValueRule selector="//par" idValue="concat('par_', position(), '_of_', last())"/>

* [**Separating Precedence of 2 Types of Inheritance**](http://lists.w3.org/Archives/Public/public-i18n-its-ig/2013Aug/0007.html)

I was unclear about ITS precedence when dealing with different types of inheritance. An element might inherit ITS information from another element with local markup or from an element selected via a global rule. But no precedence was specified between these different types of inheritance, and I wondered if local inheritance would be beat by explicit global selection.

The answer was a more explicit specification of application precedence:

1.  local markup
2.  inherited local markup
3.  global selectors
4.  inheritance from global selectors
5.  default values

Implementors can apply these rules in reverse order to get obtain a correct document model.

* [**ITS-Version in HTML**](http://lists.w3.org/Archives/Public/public-i18n-its-ig/2013Aug/0021.html)

The XML2HTML converter was converting `its:version` into `its-version` in HTML. This was then being marked as invalid by the NU validator. The IG members told me that ITS in HTML5 has no version, as HTML5 has no version. They also noted that this should be added to the specification.

* [**ITS Reset for Inherited Metadata**](http://lists.w3.org/Archives/Public/public-i18n-its-ig/2013Aug/0001.html)

There are some some ITS metadata categories that inherit but do not have a default value. This was problematic in the WICS converter application (see the limitations on `ITS::XML2HTML` and `ITS::XLIFF2HTML` listed in the Programming Guide), but may also have the potential of becoming annoying to other ITS users. For example, say that a localization note applies to the entire document, except for one deeply nested element. It is not possible to represent this using ITS, since the deeply nested element will inherit the `its:locNote` value of its ancestors, and there is no default `its:locNote` value to set on the child (Actually the default is the absence of a note, but that is not explicitly representable.).

I suggested new general ITS markup to prevent inheritance of a given category. I was told to add this to the ITS wiki.

* [**Namespace-less Atts in ITS standard**](http://lists.w3.org/Archives/Public/public-i18n-its-ig/2013Aug/0027.html)

There are a few elements in the ITS namespace which can contain ITS attributes in the null namespace. These are `<its:rules>` and standoff elements (which can contain a limited number of unprefixed attributes), and `<its:locNote>` and `<its:span>` (both of which can contain any `its:*` attribute without the `its:` prefix). While this case is documented for `<its:rules>`, it remained undocumented for the other elements, and I had to reference the RNG schemas to see why I was generating bad output from the data in the ITS 2.0 test suite. I also found that there were no examples of the usage of `<its:span>` in the entire specification. IG members suggested I add an edit suggestion on the wiki.

* [**Exclusivity and atomicity of local and global ITS**](http://lists.w3.org/Archives/Public/public-i18n-its-ig/2013Oct/0006.html)

I received clarification on what was expected behavior in two types of situations:

1. ITS metadata is organized into categories, and these categories match and override atomically. As long as documents are valid as determined by the provided schemas, this is really only relevant for the `provenance` and `locQualityIssue` categories. For example, say there's a `provRule` that matches element X, and references a `<provenanceRecords>` element that contains `person` and `org` information, and local markup on X only specifies `tool`. The local information on X would override all provenance info provided by the `provRule`, including erasing the `org` and `person` information, which was not specified locally. With `locQualityIssue`, it is possible to have a global rule specifying `locQualityIssueType` and local markup specifying a
`locQualityIssueComment`; in this case, the element would have only a `locQualityIssueComment`.

2. If a rule has a pointer attribute that doesn't match, the rule still matches. The processing software is responsible for throwing an error or generating a warning when an attempt to access the value of the pointer occurs. For example, say that the selector for the rule `<its:termRule selector="//term" term="yes"  termInfoPointer="../def"/>` matched a `<term>` element, but its termInfoPointer did not match anything. The rule would still match and mark the `<term>` element contents as a term, but an error or warning would be generated when the term info was accessed.

* [**ITS spec possible typos**](http://lists.w3.org/Archives/Public/public-i18n-its-ig/2013Oct/0018.html)

I turned in a small list of typos and possible errors I had found in the test suite, including several types of pointers previously retired from the spec that still present in the RNG schema.

* [**Differentiate Source and Target Notes in XLIFF Mapping**](http://lists.w3.org/Archives/Public/public-i18n-its-ig/2013Sep/0006.html)

Localization notes in the XLIFF ITS mapping are placed in the `<note>` element inside of a `<trans-unit>`. The XLIFF specification provides an `annotates` attribute that have may have the values `general`, `source` and `target`, depending on what the note should apply to. The XLIFF mapping only provided a mapping for the `general` note. I suggested they add the other possible values to the mapping, and Yves said he would do so.

* [**Illegal itemprops in ITS test suite**](https://github.com/finnle/ITS-2.0-Testsuite/pull/23)

The HTML5 contained in the ITS test suite used `itemprops` with specifying an item in several places, invalidating the HTML.

* [**xml:id and provenanceRecordsRef switched in ITS test suite**](https://github.com/finnle/ITS-2.0-Testsuite/pull/22)

The test suite contained illegal `xml:id` values containing `#` characters. It turned out that these were switched with `provenanceRecordsRef` values. This brought some other problems to the maintainer's attention, and this was discussed on the MultilingualWeb-LT list [here](http://lists.w3.org/Archives/Public/public-multilingualweb-lt-tests/2013Aug/0000.html).

* [**Incorrect ITS in XLIFF files in ITS test suite**](https://github.com/w3c/its-2.0-testsuite/issues/2#issuecomment-25061424)

There were several types of errors in the ITS mark in the XLIFF files in the test suite. This is sort of expected, as the mapping is still being worked out. This does cause some failing tests for the XML2XLIFF converter (they are optional tests not required for install).

* [**Typos in XLIFF Mapping**](http://lists.w3.org/Archives/Public/public-i18n-its-ig/2013Sep/0005.html)

I found a couple of typos in the XLIFF mapping; `itsx` should have been `itsxlf`, and `targetLocaleRule` should have been `targetPointerRule`.

* [**"nel" Value for its:lineBreakType**](http://lists.w3.org/Archives/Public/public-i18n-its-ig/2013Sep/0017.html)

The `its:lineBreakType` contains the name of the type of line break to use in an element (`clrf`, `lf`, etc.). I found the value "nel" in the test suite and in the RNG schema, but it was not described in the specification. The IG members said that this value was supposed to have been removed, and continued the discussion [here](http://lists.w3.org/Archives/Public/public-multilingualweb-lt-tests/2013Sep/0004.html) on the  MultilingualWeb-LT mailing list. Fixing this apparently found more [problems](http://lists.w3.org/Archives/Public/public-multilingualweb-lt-tests/2013Sep/0013.html).

* [**ITS Rules in XLIFF**](http://lists.w3.org/Archives/Public/public-i18n-its-ig/2013Sep/0029.html)

I was unsure as to whether ITS global rules were allowed in XLIFF ITS, since it was not explicitly mentioned in the mapping document. After a few misunderstandings, I finally understood that the XLIFF ITS mapping was designed to localize all ITS so that implementers would not have to implement the whole ITS spec to get ITS metadata in their XLIFF documents. This meant that the XML2XLIFF converter would have to localize all global rules.

* [**Is `mtype="x-its"` required?**](http://lists.w3.org/Archives/Public/public-i18n-its-ig/2013Oct/0005.html)

The mapping made only passing mention of the `mtype` attribute of `<mrk>` elements in XLIFF. I was wondering if this needs to always be set to `x-its` if nothing else is used, and the answer was "yes".

<a id="bug"></a>
##Bug Reports

These are reports that were sent to maintainers of software that was utilized during the course of the project.

* [allow specification of directory in DZP::Sharedir](https://rt.cpan.org/Ticket/Display.html?id=83773)
* [change running order of DZP::Sharedir](https://rt.cpan.org/Ticket/Display.html?id=83773)
* [XPath requires lower-casing to query attributes in Chromium](https://code.google.com/p/chromium/issues/detail?id=179453&thanks=179453&ts=1362167145)
* [Process variables in XML::Twig](https://github.com/mirod/xmltwig/issues/8)
* [printing wrong doctype in XML::LibXML](https://rt.cpan.org/Ticket/Display.html?id=87089)
* [unique_key method in XML::LibXML::Node](https://rt.cpan.org/Ticket/Display.html?87425) ([pull request](https://bitbucket.org/shlomif/perl-xml-libxml/pull-request/20/unique_key-method-for-nodes/diff))
* [unique_key method in XML::LibXML::Namespace](https://bitbucket.org/shlomif/perl-xml-libxml/pull-request/24)
* [-M crashes pp if option contains backslashes](https://rt.cpan.org/Ticket/Display.html?88297)
* [IPC-Cmd blocks if command reads <STDIN> (on Win32)](https://rt.cpan.org/Ticket/Display.html?88315)
* [MBP:CPANfile Crashes perl on Windows during install](https://rt.cpan.org/Ticket/Display.html?88304)
* [Capture::Tiny Crashes with fork on Windows](https://github.com/dagolden/capture-tiny/issues/12)
* [Module::Build::Pluggable uses fork](https://github.com/tokuhirom/Module-Build-Pluggable/issues/2)
* [Use IO::Prompt::Tiny in Metabase::Fact](https://github.com/dagolden/metabase-fact/pull/2)
* [Win32::Unicode test failure](https://github.com/xaicron/p5-win32-unicode/issues/3)
* [Null namespace crashes HTML::HTML5::Writer](https://rt.cpan.org/Ticket/Display.html?id=88621)
* [Space required to Parse File with HTML::HTML5::Parser](https://rt.cpan.org/Ticket/Display.html?id=88636)
* [Compare all types of nodes with Test::XML::Ordered](https://rt.cpan.org/Ticket/Display.html?id=88994)
* [Log::Any- don't `require` loaded packages](https://github.com/dagolden/Log-Any/pull/2)
