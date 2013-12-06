#!perl
#
# This file is part of ITS-WICS
#
# This software is Copyright (c) 2013 by DFKI.
#
# This is free software, licensed under:
#
#   The MIT (X11) License
#

use Test::More;

eval "use Test::CPAN::Meta";
plan skip_all => "Test::CPAN::Meta required for testing META.yml" if $@;
meta_yaml_ok();
