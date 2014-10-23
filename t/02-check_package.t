#!perl

use warnings;
use strict;
use Test::Config::System;

my @pkgmgrs = ('/usr/bin/dpkg', '/bin/rpm');
my $pkgmgr;

for my $path (@pkgmgrs) {
    (($pkgmgr) = $path =~ m!/([^/]+)$!, last) if (-x $path);
}

if ($pkgmgr) {
    plan(tests => 2);
    check_package('this-just-cant-be-a-real-package_FNORD', 'bogus package not installed', 1, $pkgmgr);
    check_package('perl', 'check_package(perl)', 0, $pkgmgr);
} else {
    plan(skip_all => 'no suitable package manager found, skipping check_package tests');
}
