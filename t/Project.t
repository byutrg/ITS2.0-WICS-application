use strict;
use warnings;
use FindBin '$Bin';
use Path::Tiny;
use Test::More;
plan tests => 8;
use ITS::WICS::Project 'update_project';

test_new_project();
test_update_project();

# create a new project and verify its contents
sub test_new_project {
    my $temp = Path::Tiny->tempdir;
    update_project($temp);
    my $iter = $temp->iterator({recurse => 1});
    ok(path($temp, '.WICS', 'css', 'wics_stylesheet.css')->exists,
        'CSS stylesheet added to new project');

    ok(path($temp, '.WICS', 'scripts', 'jquery-1.9.1.min.js')->exists,
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

    ok(-M path($dir, '.WICS', 'scripts', 'jquery-1.9.1.min.js') > 0,
        'JQuery added to new project');

    ok(-M path($dir, '.WICS', 'scripts', 'wics.js') > 0,
        'wics.js added to new project');

    ok(-M path($dir, '.WICS', 'colors.txt') > 0,
        'colors.txt added to new project');
    return;
}
