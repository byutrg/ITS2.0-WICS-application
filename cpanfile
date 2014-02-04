requires "Carp" => "0";
requires "Data::Dumper" => "0";
requires "Encode" => "0";
requires "Exporter::Easy" => "0";
requires "File::ShareDir::PAR" => "0";
requires "Getopt::Lucid" => "0";
requires "HTML::HTML5::Parser" => "0";
requires "HTML::HTML5::Writer" => "0";
requires "List::MoreUtils" => "0";
requires "Log::Any" => "0";
requires "Log::Any::Adapter" => "0";
requires "Log::Any::Adapter::Base" => "0";
requires "Log::Any::Adapter::Util" => "0";
requires "Path::Tiny" => "0";
requires "Try::Tiny" => "0";
requires "URI" => "0";
requires "Wx" => "0";
requires "Wx::Perl::Packager" => "0";
requires "XML::LibXML" => "0";
requires "autodie" => "0";
requires "base" => "0";
requires "feature" => "0";
requires "parent" => "0";
requires "perl" => "5.010";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.3601";
};

on 'test' => sub {
  requires "Data::Section::Simple" => "0";
  requires "File::Find" => "0";
  requires "File::Path" => "0";
  requires "File::Slurp" => "0";
  requires "File::Temp" => "0";
  requires "FindBin" => "0";
  requires "HTTP::Message" => "0";
  requires "IO::Compress::Gzip" => "0";
  requires "LWP::UserAgent" => "0";
  requires "Log::Any::Test" => "0";
  requires "Test::Base" => "0";
  requires "Test::Base::Filter" => "0";
  requires "Test::Exception" => "0";
  requires "Test::HTML::Differences" => "0";
  requires "Test::More" => "0.88";
  requires "Test::NoWarnings" => "0";
  requires "Test::Warn" => "0";
  requires "Test::XML" => "0";
  requires "utf8" => "0";
};

on 'configure' => sub {
  requires "File::ShareDir::Install" => "0.03";
  requires "Module::Build" => "0.3601";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "version" => "0.9901";
};
