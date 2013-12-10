use strict;
use warnings;
use Test::More 0.88;
# This is a relatively nice way to avoid Test::NoWarnings breaking our
# expectations by adding extra tests, without using no_plan.  It also helps
# avoid any other test module that feels introducing random tests, or even
# test plans, is a nice idea.
our $success = 0;
END { $success && done_testing; }
diag('I"m in Tiny.pm right now');
# List our own version used to generate this
my $v = "\nGenerated by Dist::Zilla::Plugin::ReportVersions::Tiny v1.08\n";

eval {                     # no excuses!
    # report our Perl details
    my $want = '5.014';
    $v .= "perl: $] (wanted $want) on $^O from $^X\n\n";
};
defined($@) and diag("$@");

# Now, our module version dependencies:
sub pmver {
    my ($module, $wanted) = @_;
    $wanted = " (want $wanted)";
    my $pmver;
    eval "require $module;";
    if ($@) {
        if ($@ =~ m/Can't locate .* in \@INC/) {
            $pmver = 'module not found.';
        } else {
            diag("${module}: $@");
            $pmver = 'died during require.';
        }
    } else {
        my $version;
        eval { $version = $module->VERSION; };
        if ($@) {
            diag("${module}: $@");
            $pmver = 'died during VERSION check.';
        } elsif (defined $version) {
            $pmver = "$version";
        } else {
            $pmver = '<undef>';
        }
    }

    # So, we should be good, right?
    return sprintf('%-45s => %-10s%-15s%s', $module, $pmver, $wanted, "\n");
}

eval { $v .= pmver('Carp','any version') };
eval { $v .= pmver('Data::Dumper','any version') };
eval { $v .= pmver('Data::Section::Simple','any version') };
eval { $v .= pmver('Encode','any version') };
eval { $v .= pmver('Exporter::Easy','any version') };
eval { $v .= pmver('File::Find','any version') };
eval { $v .= pmver('File::Path','any version') };
eval { $v .= pmver('File::ShareDir::Install','0.03') };
eval { $v .= pmver('File::ShareDir::PAR','any version') };
eval { $v .= pmver('File::Slurp','any version') };
eval { $v .= pmver('File::Temp','any version') };
eval { $v .= pmver('FindBin','any version') };
eval { $v .= pmver('Getopt::Lucid','any version') };
eval { $v .= pmver('HTML::HTML5::Parser','any version') };
eval { $v .= pmver('HTML::HTML5::Writer','any version') };
eval { $v .= pmver('HTTP::Message','any version') };
eval { $v .= pmver('IO::Compress::Gzip','any version') };
eval { $v .= pmver('LWP::UserAgent','any version') };
eval { $v .= pmver('List::MoreUtils','any version') };
eval { $v .= pmver('Log::Any','any version') };
eval { $v .= pmver('Log::Any::Adapter','any version') };
eval { $v .= pmver('Log::Any::Adapter::Base','any version') };
eval { $v .= pmver('Log::Any::Adapter::Util','any version') };
eval { $v .= pmver('Log::Any::Test','any version') };
eval { $v .= pmver('Module::Build','0.3601') };
eval { $v .= pmver('Path::Tiny','any version') };
eval { $v .= pmver('Pod::Coverage::TrustPod','any version') };
eval { $v .= pmver('Test::Base','any version') };
eval { $v .= pmver('Test::Base::Filter','any version') };
eval { $v .= pmver('Test::CPAN::Meta','any version') };
eval { $v .= pmver('Test::Exception','any version') };
eval { $v .= pmver('Test::HTML::Differences','any version') };
eval { $v .= pmver('Test::More','0.88') };
eval { $v .= pmver('Test::NoWarnings','any version') };
eval { $v .= pmver('Test::Pod','1.41') };
eval { $v .= pmver('Test::Pod::Coverage','1.08') };
eval { $v .= pmver('Test::Warn','any version') };
eval { $v .= pmver('Test::XML','any version') };
eval { $v .= pmver('Try::Tiny','any version') };
eval { $v .= pmver('URI','any version') };
eval { $v .= pmver('Wx','any version') };
eval { $v .= pmver('Wx::Perl::Packager','any version') };
eval { $v .= pmver('XML::LibXML','any version') };
eval { $v .= pmver('autodie','any version') };
eval { $v .= pmver('base','any version') };
eval { $v .= pmver('feature','any version') };
eval { $v .= pmver('parent','any version') };
eval { $v .= pmver('strict','any version') };
eval { $v .= pmver('utf8','any version') };
eval { $v .= pmver('version','0.9901') };
eval { $v .= pmver('warnings','any version') };


# All done.
$v .= <<'EOT';

Thanks for using my code.  I hope it works for you.
If not, please try and include this output in the bug report.
That will help me reproduce the issue and solve your problem.

EOT

diag($v);
ok(1, "we really didn't test anything, just reporting data");
$success = 1;

# Work around another nasty module on CPAN. :/
no warnings 'once';
$Template::Test::NO_FLUSH = 1;
exit 0;
