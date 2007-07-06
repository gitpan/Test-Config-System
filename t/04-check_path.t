#!perl

use warnings;
use strict;

use Test::Config::System tests => 2;

check_dir('lib', { '-mode' => 0755 });
check_file('lib/Test/Config/System.pm', { '-mode' => 0644});
# Difficult to test anything else in at least a semi-portable manner..
