package XML::ITS::XML;
use strict;
use warnings;
use Carp;
our @CARP_NOT = qw(XML::ITS);
use Path::Tiny;
use Try::Tiny;
use XML::ITS::RuleContainer;
use XML::ITS::Rule;
use parent -norequire, qw(XML::ITS);

# Find and save all its:rules elements containing rules to be applied in
# the given document, in order of application, including external ones.
# %params are all of the parameters already defined for this document.
sub _resolve_doc_containers {
    # note that we don't pass around hash pointers for the params so that
    # all parameters are correctly scoped for each document or its:rules element.
    my ($self, $doc, %params) = @_;

    # first, grab internal its:rules elements
    my @internal_rules_containers = _get_its_rules_els($doc);
    if(@internal_rules_containers == 0){
        return [];
    }

    # then store individual rules in application order (external first)
    my @containers;
    for my $container (@internal_rules_containers){

        my $containers =
            $self->_resolve_containers(
                $doc,
                $container,
                %params
            );
        push @containers, @{$containers};
    }

    if(@containers == 0){
        carp 'no rules found in ' . $doc->get_source;
    }
    return \@containers;
}

sub _get_its_rules_els {
    my ($doc) = @_;
    return $doc->get_root->get_xpath(
        q<//*[namespace-uri()='> . XML::ITS::its_ns() . q<'> .
            q{and local-name()='rules']},
    );
}

sub _resolve_containers {
    my ($self, $doc, $container, %params) = @_;

    my $children = $container->child_els();

    if(@$children){
        while( $children->[0]->local_name eq 'param' and
            $children->[0]->namespace_URI eq XML::ITS::its_ns() ){
            my $param = shift @$children;
            $params{$param->att('name')} = $param->text;
        }
    }
    my @containers;
    if($container->att( 'href', XML::ITS::xlink_ns() )){
        #path to file is relative to current file
        my $path = path( $container->att( 'href', XML::ITS::xlink_ns() ) )->
            absolute($doc->get_base_uri);
        push @containers, @{ $self->_get_external_containers($path, \%params) };
    }
    push @containers, XML::ITS::RuleContainer->new(
            version => $container->att('version'),
            query_language =>
                $container->att('queryLanguage') || 'xpath',
            params => \%params,
            rules => $children,
        );
    return \@containers;
}

sub _get_external_containers {
    my ($self, $path, $params) = @_;
    my $doc;

    try {
        $doc = XML::ITS::DOM->new('xml' => $path );
    } catch {
        carp "Skipping rules in file '$path': $_";
        return [];
    };
    return $self->_resolve_doc_containers($doc, %$params);
}

1;