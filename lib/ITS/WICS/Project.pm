use strict;
use warnings;
use Carp;
use Path::Tiny;
use File::ShareDir 'dist_dir';
# VERSION
# ABSTRACT: Manage WICS project folder

=head1 SYNOPSIS

    use ITS::WICS::Project qw(update_project);
    my $dir = 'path/to/project/folder';
    update_project($dir);
    # $dir now contains latest JS and CSS code for dynamic ITS display

=head1 DESCRIPTION

This simple module keeps a WICS project folder up-to-date. A WICS
project folder is simply one which contains the JavaScript and CSS
files for dynamically displaying ITS in HTML files that link to it.

=cut

my $latest_version = _get_latest_version();

sub _get_latest_version {
    my $version_file = path( dist_dir('ITS-WICS'),'VERSION' );
    $version_file->exists or
        croak "Couldn't find share directory!";
    return _version_from_file($version_file);
}

=head2 C<update_project>

Given a path to a project directory, check if its .WICS directory
contains viewer code newer than the version used by this distribution,
and if it does not then update the code contained inside by copying
over it with the current version.

Returns false if the directory contained a newer WICS viewer code,
and true otherwise.

=cut
sub update_project {
    my ($path) = @_;
    my $code_dir = path($path, '.WICS');
    $code_dir->mkpath;
    if(_is_newer($code_dir)){
        return;
    }
    # copy everything from the share dir into the code dir,
    # in case anything got changed by a user
    my $share_dir = path(dist_dir('ITS-WICS'));
    my $iter = $share_dir->iterator({recurse => 1});
    while(my $file = $iter->()){
        my $destination = path($code_dir, $file->relative($share_dir));
        # breadth-first iteration guarantees we'll get
        # the directories that need creating before
        # files
        if($file->is_dir){
            $destination->mkpath;
            next;
        }
        # delete old file
        if($destination->exists){
            $destination->remove;
        }
        $file->copy($destination);
    }
}

# return true if the given path contains WICS viewer code newer than
# that used by this distribution.
sub _is_newer {
    my ($path) = @_;
    my $version_file = path($path, 'VERSION');
    return unless $version_file->exists;
    my $version = _version_from_file($version_file);
    return $version > $latest_version;
}


# Retrieve a version number from the input file.
# The file should contain a single line formatted like this:
# "X.XX (sha1)", where X.XX is the version and the sha1 identifies
# the commit in the ITS2.0-WICS-viewer where the dynamic viewer code
# was taken from
sub _version_from_file {
    my ($version_file) = @_;

    my $contents = $version_file->slurp_utf8;
    my ($version) = $contents =~ /^([0-9.]+) \(/g;
    if(!$version){
        croak "Couldn't find version number in $version_file!";
    }
    return $version;
}

# given the project code location, check that all of the expected
# files are present
sub _missing_files {
    my ($path) = @_;
    my $share_dir = path(dist_dir('ITS-WICS'));
    my $iter = $share_dir->iterator;
    while(my $file = $iter->()){
        my $expected = path($path, $file->relative($share_dir));
        if(!$expected->exists){
            return 1;
        }
    }
    return 0;
}

1;
