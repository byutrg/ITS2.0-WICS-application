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

eval 'use Test::Portability::Files';
plan skip_all => 'Test::Portability::Files required for testing portability'
    if $@;
run_tests();
