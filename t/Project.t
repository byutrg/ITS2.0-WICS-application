# Test ITS::WICS::Project.pm
# TODO: test exceptions
use strict;
use warnings;
use FindBin '$Bin';
use Path::Tiny;
use Test::More;
plan tests => 15;
use ITS::WICS::Project qw(update_project code_links link_doc);

test_new_project();
test_update_project();
test_code_links();
test_link_doc();

# create a new project and verify its contents
sub test_new_project {
    my $temp = Path::Tiny->tempdir;
    update_project($temp);
    my $iter = $temp->iterator({recurse => 1});
    ok(path($temp, '.WICS', 'css', 'wics_stylesheet.css')->exists,
        'CSS stylesheet added to new project');

    ok(path($temp, '.WICS', 'scripts', 'jquery-1_9_1_min.js')->exists,
        'JQuery added to new project');

    ok(path($temp, '.WICS', 'scripts', 'wics.js')->exists,
        'wics.js added to new project');

    ok(path($temp, '.WICS', 'colors.txt')->exists,
        'colors.txt added to new project');
    return;
}

# update the example project in corpus and verify that its contents
# have been renewed
sub test_update_project {
    my $dir = path($Bin, 'corpus', 'project');
    update_project($dir);

    # -M > 0 means it has been modified since the script start time
    ok(-M path($dir, '.WICS', 'css', 'wics_stylesheet.css') > 0,
        'CSS stylesheet added to new project');

    ok(-M path($dir, '.WICS', 'scripts', 'jquery-1_9_1_min.js') > 0,
        'JQuery added to new project');

    ok(-M path($dir, '.WICS', 'scripts', 'wics.js') > 0,
        'wics.js added to new project');

    ok(-M path($dir, '.WICS', 'colors.txt') > 0,
        'colors.txt added to new project');
    return;
}

sub test_code_links {
    my ($css_link, $jq_link, $wics_link) = code_links();
    my $html_ns = 'http://www.w3.org/1999/xhtml';
    subtest 'CSS link' => sub {
        plan tests => 5;
        is($css_link->name, 'link', 'is a <link> element');
        is($css_link->att('href'),
            '.WICS/css/wics_stylesheet.css', 'correct href');
        is($css_link->att('rel'),
            'stylesheet', 'correct rel');
        is($css_link->att('type'),
            'text/css', 'correct type');
        is($css_link->namespace_URI, $html_ns,
            'in HTML namespace');
    };
    subtest 'jQuery link' => sub {
        plan tests => 4;
        is($jq_link->name, 'script', 'is a <script> element');
        is($jq_link->att('src'),
            '.WICS/scripts/jquery-1_9_1_min.js', 'correct src');
        is($jq_link->att('type'),
            'text/javascript', 'correct type');
        is($jq_link->namespace_URI, $html_ns,
            'in HTML namespace');
    };
    subtest 'wics JS link' => sub {
        plan tests => 4;
        is($wics_link->name, 'script', 'is a <script> element');
        is($wics_link->att('src'),
            '.WICS/scripts/wics.js', 'correct src');
        is($wics_link->att('type'),
            'text/javascript', 'correct type');
        is($wics_link->namespace_URI, $html_ns,
            'in HTML namespace');
    };
}

sub test_link_doc {
    my $html_doc = ITS::DOM->new(
        html => \'<!DOCTYPE html><html>');
    link_doc($html_doc);
    my $head = ( $html_doc->get_root->children )[0];
    my @children = $head->children;
    is(scalar $head->children, 3, 'three elements added to head');
    is($children[0]->att('href'), '.WICS/css/wics_stylesheet.css',
        'head contains css link');
    is($children[1]->att('src'), '.WICS/scripts/jquery-1_9_1_min.js',
        'head contains wics jQuery link');
    is($children[2]->att('src'), '.WICS/scripts/wics.js',
        'head contains wics.js link');
}
