#!perl

use warnings;
use strict;
use Test::Config::System;


if (-x '/usr/bin/dpkg') {
    plan(tests => 2);
    check_package('this-just-cant-be-a-real-package_FNORD', 'bogus package not installed', 1);
    check_package('perl', 'perl installed');
} else {
    plan(skip_all => 'dpkg not found, skipping check_package tests');
}
