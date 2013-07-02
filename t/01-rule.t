# Test Rule methods

use strict;
use warnings;
use ITS;
use Test::More 0.88;
plan tests => 5;
use Test::Warn;
use Test::NoWarnings;
use XML::Twig;

subtest 'basic rule' => sub {
    plan tests => 4;
    my $attributes = {
        'xmlns:its' => 'http://www.w3.org/2005/11/its',
        'selector' => 'id("id_1")',
        'storageSize' => '8',
        'storageEncoding' => 'UTF-8',
    };
    my $el = XML::Twig::Elt->new('its:storageSizeRule' => $attributes);
    my $rule = ITS::Rule->new($el);
    is($rule->type, 'storageSize', 'rule name');
    is_deeply($rule->atts, $attributes, 'rule attributes');
    is($rule->att('storageSize'), '8', 'attribute accessor');
    is_deeply($rule->params, {}, 'no parameters');
};

subtest 'parameters' => sub {
    plan tests => 1;
    my $params = {
        x => 'x value',
        y => 'y value',
    };
    my $el = XML::Twig::Elt->new(
        'its:storageSizeRule' => {
            'xmlns:its' => 'http://www.w3.org/2005/11/its',
            'selector' => 'id("id_1")',
            'storageSize' => '8',
            'storageEncoding' => 'UTF-8',
        }
    );
    my $rule = ITS::Rule->new($el, $params);
    is($rule->params, $params, 'parameter values')
};

subtest 'pointer attributes' => sub {
    plan tests => 1;
    my $el = XML::Twig::Elt->new(
        'its:storageSizeRule' => {
            'xmlns:its' => 'http://www.w3.org/2005/11/its',
            'selector' => 'id("id_1")',
            'storageSizePointer' => '@size',
            'storageEncodingPointer' => '@encoding',
        }
    );
    my $rule = ITS::Rule->new($el);
    is_deeply($rule->pointers,
        [qw(storageEncodingPointer storageSizePointer)],
        'pointer attributes'
    );
};

my $el = XML::Twig::Elt->new(
    'its:storageSizeRule' => {
        'xmlns:its' => 'http://www.w3.org/2005/11/its',
        'storageSizePointer' => '@size',
        'storageEncodingPointer' => '@encoding',
    }
);
warning_is {my $rule = ITS::Rule->new($el)}
    'storageSize rule is missing selector! No nodes will match.',
    'warn on missing selector';
