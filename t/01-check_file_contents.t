#!perl

use warnings;
use strict;
use Test::Config::System tests => 2;

check_file_contents('lib/Test/Config/System.pm', qr/^package Test::Config::System;/, 'module matches /^package Test::Config::System;/');
check_file_contents('/bogus/file/-/aoeu', qr//, 'bogus file does not exist', 1);
