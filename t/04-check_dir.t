#!perl

use warnings;
use strict;

use Test::Config::System tests => 1;

check_dir('lib');
# Difficult to test anything else in at least a semi-portable manner..
