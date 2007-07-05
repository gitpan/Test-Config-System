#!perl

use warnings;
use strict;

use File::Temp qw /tempfile/;
use Test::Config::System;


if (eval { symlink("",""); 1 }) {      # if FS does symlinks
    my ($d1, $tmp) = tempfile();
    unlink $tmp;
    if (symlink("lib/Test/Config/System.pm", $tmp)) {
        plan(tests => 1);
        check_link($tmp, "lib/Test/Config/System.pm");
        unlink $tmp;
    } else {
        plan( skip_all => 'could not create symlink' );
    }
} else {
    plan( skip_all => 'filesystem does not support symlinks');
}

