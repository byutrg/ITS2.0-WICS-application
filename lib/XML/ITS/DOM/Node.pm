package XML::ITS::DOM::Node;
use strict;
use warnings;
# VERSION
# ABSTRACT: thin wrapper around underlying XML engine node objects
use XML::ITS::DOM::Value;
use Carp;
use feature 'switch';

=head1 SYNOPSIS

    use XML::ITS::DOM;
    use feature 'say';
    my $dom = XML::ITS::DOM->new(xml => 'path/to/file');
    my @nodes = $dom->get_xpath('//@foo');
    for my $node(@nodes){
        say $node->text;
    }

=head1 DESCRIPTION

This module is meant for internal use by the ITS::* modules only.
It is a thin wrapper around an XML::LibXML::Node.

=head1 METHODS

=head2 C<new>

Argument: a single XML::LibXML node.

Note that this constructor DOES NOT support subclassing by other libraries. The
package of the returned object depends on the type of XML::LibXML node passed in.


=cut
sub new {
    my ($class, $node) = @_;
    my $type = _get_type($node);

    #why subclassing isn't supported; class names are hard-coded
    if($type eq 'ELT'){
        $class = 'XML::ITS::DOM::Element';
    }else{
        $class = 'XML::ITS::DOM::Node';
    }
    return bless {
        node => $node,
        type => _get_type($node),
    }, $class;
}

sub _get_type {
    my ($node) = @_;
    my $type;
    if(!$node->can('nodeType')){
        #has to be a literal, number or boolean
        if(ref $node eq 'XML::LibXML::Literal'){
            $type = 'LIT';
        }else{
            $type = ref $node;
            $type =~ s/.*:://;
            croak "ITS doesn't support nodes of type $type";
        }
    }
    else{
        given($node->nodeType){
            when(1){$type = 'ELT'; break;}
            when(2){$type = 'ATT'; break;}
            when(3){$type = 'TXT'; break;}
            when(18){$type = 'NS'; break;}
            when(7){$type = 'PI'; break;}
            when(8){$type = 'COM'; break;}
            when(9){$type = 'DOC'; break;}
            default{croak "unknown node type for $node";}
        }
    }
    return $type;
}

=head2 C<get_xpath>

Constructs an xpath query from the input arguments, and returns
a list of nodes matching the query.

The xpath context node will be the calling node, and the first argument should be
the XPath string. The rest of the parameters are named and optional:

=over 3

=item position

An integer indicating the context position. Default is -1.

=item size

An integer indicating the context size. Default is -1.

=item params

A hash ref containing variable names and strings values. No other
types of values are allowed. There are no default parameters.

=item namespaces

A hash ref of namespace prefix keys and namespace URI values to be
made available to the XPath expression. Any previously scoped namespaces
are removed (by default, all namespaces in the scope of the context node
are available, but providing a namespaces value removes these).

=back

=cut

sub get_xpath {
    my ($self, $xpath, %context) = @_;

    #set up the XPath context with the given information
    my $xpc = XML::LibXML::XPathContext->new($self->{node});
    if($context{params}){
        $xpc->registerVarLookupFunc(\&_var_lookup, $context{params});
    }
    if($context{namespaces}){
        # my $old_namespaces = $self->get_namespaces;
        # for(keys %$old_namespaces){
        #     print "trying to unregister $_\n";
        #     $xpc->unregisterNs($_);
        # }
        $xpc->registerNs($_, $context{namespaces}->{$_})
            for keys %{ $context{namespaces} };
    }
    # print $xpc->lookupNs('bar');
    if($context{size}){
        $xpc->setContextSize($context{size});
    }
    if($context{position}){
        $xpc->setContextPosition($context{position});
    }

    my $object;
    #TODO: catch errors and clean up the stack trace
    # try{
        $object = $xpc->find($xpath);
    # }catch{
    #     croak "Problem evaluating XPath: $_";
    # };
    my @nodes;
    if(ref $object eq 'XML::LibXML::NodeList'){
        @nodes =
            map {XML::ITS::DOM::Node->new($_)}
            $object->get_nodelist();
    }else{
        push @nodes, XML::ITS::DOM::Value->new($object);
    }
    return @nodes;
}

#simple dictionary-lookup sub for parameter handling in get_xpath method
sub _var_lookup {
    my ($data, $varname, $ns) = @_;
    my $lookup = $varname;
    if(defined $ns){
        $lookup = "$ns:$lookup";
    }
    my $val = $data->{$lookup};
    if (!defined($val)) {
        warn("Unknown variable \"$lookup\"\n");
        $val = '';
    }
    return $val;
}

=head2 C<type>

Returns a string representing the type of the node:
C<ELT>, C<ATT>, C<TXT>, C<NS>, C<PI>, C<COM> or C<DOC>.

=cut
sub type {
    my ($self) = @_;
    return $self->{type};
}

=head2 C<name>

Returns the name of the node. This is the tag name for elements,
the name for attributes and PIs, etc.

=cut
sub name {
    my ($self) = @_;
    return $self->{node}->nodeName;
}

=head2 C<set_name>

Sets the node's name to the given string. Is namespace aware.

=cut
sub set_name {
    my ($self, $name) = @_;
    $self->{node}->setNodeName($name);
}

=head2 C<remove>

Unbinds this node from it's siblings and parents (but not
the document, though it invisible).

=cut
sub remove {
    my ($self) = @_;
    $self->{node}->unbindNode;
}

=head2 C<namespaceURI>

Returns the namespace URI of this node.

=cut
sub namespaceURI {
    my ($self) = @_;
    return $self->{node}->namespaceURI;
}

=head2 C<local_name>

Returns the node name without the namespace prefix.

=cut
sub local_name {
    my ($self) = @_;
    return $self->{node}->localname;
}

=head2 C<value>

Returns a string representing the value of the node. This is not
text content for elements (call L<text> for that).

=cut
sub value {
    my ($self) = @_;
    return $self->{node}->nodeValue;
}

=head2 C<text>

Returns the content of all text nodes in the descendants of this node.

=cut
sub text {
    my ($self) = @_;
    return $self->{node}->textContent;
}

=head2 C<get_namespaces>

Returns a hash ref containing prefix/URI pairs for all of the namespaces
in scope for this node.

=cut
sub get_namespaces {
    my ($self) = @_;
    my @namespaces = $self->get_xpath('namespace::*');
    my %namespaces;
    $namespaces{$_->{node}->getLocalName} = $_->{node}->getData
        for @namespaces;
    return \%namespaces;
}

=head2 C<children>

Returns a list containing the
child nodes of this node.

=cut
sub children {
    my ($self) = @_;
    return map {XML::ITS::DOM::Node->new($_)}
        $self->{node}->childNodes;
}

=head2 C<parent>

Returns the parent node of this node.

=cut
sub parent {
    my ($self) = @_;
    return __PACKAGE__->new($self->{node}->parentNode);
}

=head2 C<paste>

Paste this node into the given relation with the given node.
The arguments are another node, and an optional relation.
The possible relations are C<last_child>, C<first_child>,
C<before> and C<after>. The default is C<last_child>.

=cut
sub paste {
    my ($self, $other, $loc) = @_;

    $loc ||= 'last_child';
    my $this_node = $self->{node};
    my $o_node = $other->{node};

    if($loc eq 'last_child'){
        $o_node->appendChild($this_node);
    }elsif($loc eq 'first_child'){
        $o_node->insertBefore($this_node, $o_node->firstChild);
    }elsif($loc eq 'before'){
        my $parent = $o_node->parentNode;
        $parent->insertBefore($this_node, $o_node);
    }elsif($loc eq 'after'){
        my $parent = $o_node->parentNode;
        $parent->insertAfter($this_node, $o_node);
    }else{
        croak "unknown paste location: $loc";
    }
    return;
}

=head2 C<is_same_node>

Return true if this node is the same node as the input node.

=cut
sub is_same_node {
    my ($self, $other) = @_;
    return $self->{node}->isSameNode($other->{node});
}

=head2 C<copy>

Returns a copy of this node. A single boolean argument indicates
whether a deep copy should be performed; that is, whether children
should also be copied.

=cut
sub copy {
    my ($self, $deep) = @_;
    return __PACKAGE__->new($self->{node}->cloneNode($deep));
}

=head2 C<unique_key>

Returns a unique integer guaranteed to always be the same for this node.
In other words, if and only if the unique key for two node objects
are the same, then is_same_node will return true.

=cut
sub unique_key {
    my ($self) = @_;
    return ${$self->{node}};
}

1;
