#!perl

use warnings;
use strict;
use Test::Config::System tests => 1;

check_file('lib/Test/Config/System.pm', qr/^package Test::Config::System;/, 'module matches /^package Test::Config::System;/');
