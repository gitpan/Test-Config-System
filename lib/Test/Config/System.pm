package Test::Config::System;

use warnings;
use strict;

use Carp;

my $CLASS = __PACKAGE__;
use base 'Test::Builder::Module';

=head1 NAME

Test::Config::System - System configuration related unit tests

=head1 VERSION

Version 0.23

=cut

our $VERSION     = '0.23';
our @EXPORT      = qw(check_package check_file check_link check_dir plan diag ok);
our $AUTOLOAD;

sub AUTOLOAD {
    my $tb = Test::Config::System->builder;
    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    $tb->$name(@_);
}

=head1 SYNOPSIS

Test::Config::System is used to help test system configuration, ie, cfengine unit
tests.

    use Test::Config::System tests => 3;
    
    check_package('less', 'package less');
    check_package('emacs21', 'emacs uninstalled', 1);
    check_link('/etc/alternatives/www-browser', '/usr/bin/w3m');
    check_file('Test/Config/System.pm', qr/do {local \$\//);

=head1 DESCRIPTION

Test::Config::System provides functions to help test system configuration, such as
installed packages or config files.  It was built for use in a cfengine
staging environment.  (L<http://www.cfengine.org>.  cfengine is used for
automating and managing system configuration at large sites).

Test::Config::System does not depend on, or interact with cfengine in any way,
however, and can be used on its own or with another configuration management
tool (such as puppet or bcfg2).

This module is a subclass of Test::Builder::Module, and is used like any other
Test::* module.  Instead of directly providing an ok() function, the functions
exported (described below), call ok() themselves, based on the outcome of the
check they preform.

=head1 EXAMPLE

    use Test::Config::System tests => 3;
    # check something we already know:  :)
    check_package('perl', 'perl is installed');
    check_file('/etc/apt/sources.list', qr/apt-proxy/,
        'apt-proxy is not being used', 1); # check that the apt-proxy does not
                                           # appear anywhere in sources.list
    check_package('vim');      # Make sure we have the one true editor


=head1 EXPORT

check_package
check_file
check_link
check_dir

From Test::Builder::Module:

plan
diag
ok

=head1 FUNCTIONS

Each of the functions below use Test::Builder::Module's ok() function to
report test success or failure.  They return the result of ok() upon normal
completion, or undef on error (eg a required parameter not provided, or FS
doesn't support symlinks).

=head2 check_package( NAME, [DESC, INVERT, PACKAGE_MANAGER] )

NOTE: check_package currently only supports dpkg.  If run on a non-dpkg
system, the test will /always/ fail.

check_package tests whether or not a package is installed.  If the package
is not installed or if the given package manager does not exist, the test
fails.  Otherwise, the test will pass.  (If the test is inverted, the outcome
is the opposite).

  - NAME: package name
  - DESC: test name (optional, defaults to package name)
  - INVERT: invert test (optional, defaults to 0.  Possible values are 0 and 1.)
  - PACKAGE_MANAGER: package manager (optional and currently ignored, defaults to 'dpkg')

Examples:
    # Will fail if nethack is not installed
    check_package('nethack-text');
    # This will fail if x11-common is installed:
    check_package('x11-common', 'x11-common is not installed', 1);

=cut

#TODO: version
#TODO: rpm support
sub check_package {
    my ($pkg, $testname, $invert, $pkgmgr);
    $pkg      = shift;
    if (!$pkg) {
        carp "Package name required";
        return undef;
    }
    $testname = (shift || $pkg);
    $invert   = (shift || 0);
    $pkgmgr   = (shift || 'dpkg');

    my $res = system("/usr/bin/dpkg -l $pkg 2>/dev/null|egrep '^ii' >/dev/null");
    $res = $res >> 8;  # get the actual return value

    my $tb = Test::Config::System->builder;
    $tb->ok($res == $invert, $testname);
}

=head2 check_file( FILENAME, REGEX, [DESC, INVERT] )

check_file tests that a file's contents match a given regex.  It slurps the
contents of the given filename, then matches it against the given regex.  If
the regex matches the contents of the file, ok() is called with a true value,
causing the test to pass.  If the regex does not match, the test will fail (as
in check_package, if the test is inverted, the results are inverted as well).

If the given file cannot be opened for reading, check_file will return
undef, and ok() will not be called.

Note that the entire file is slurped into memory at once.  This has two
concequences.  First, large files will eat up RAM.  Second, ^ and $ do not
work line-by-line, as one might expect.  "\n" can be used in place of ^ or $.

  - FILENAME: file to test
  - REGEX: regex to match (qr//-style regex)
  - DESC: test name (optional, defaults to filename)
  - INVERT: invert test (optional, defaults to 0.  Possible values are 0 and 1.)

Examples:
    check_file('/etc/fstab', qr|proc\s+/proc\s+proc\s+defaults\s+0\s+0|, 'proc is in fstab');
    check_file('/etc/passwd', qr|evilbob:x:\d+:\d+:|, 'evilbob is not in passwd', 1);

=cut

sub check_file {
    my ($filename, $regex, $testname, $invert, $res);
    $filename   = shift;
    $regex      = shift;
    if (!$filename) {
        carp "Filename required";
        return undef;
    }
    if (ref($regex) ne 'Regexp') {
        carp "qr// style regex required";
        return undef;
    }
    $testname   = (shift || $filename);
    $invert     = (shift || 0);

    $res = (open my $fh, '<', $filename) or carp "Could not open $filename for reading";
    return undef unless $res;

    my $text = do {local $/; <$fh>};
    close($fh);
    $res = ($text =~ /$regex/);

    my $tb = Test::Config::System->builder;
    $tb->ok($invert ? !$res : $res, $testname);
}

=head2 check_link( FILENAME, [TARGET, DESC, INVERT] )

check_link verifies that a symlink exists and, optionally, points to the
correct target.

If no filename is passed, it will return undef, otherwise a test will be run
and the result of ok() will be returned.

If the filesystem does not support symlinks, the test will be skipped, and
check_link will return undef.

  - FILENAME: filename (path to a symlink)
  - TARGET:   path the link should point to.  optional.  If not specified,
              check_link will ignore the target, and just verify that the link
              exists.
  - DESC: test name (optional, defaults to filename)
  - INVERT: invert test (optional, defaults to 0.  Possible values are 0 and 1.)

Examples:
    check_link('/etc/alternatives/rsh', '/usr/bin/ssh');
    check_link('/etc/sudoers', '', 'sudoers is not a symlink', 1);

=cut

sub check_link {
    my ($src, $target, $testname, $invert, $res);
    my $tb = Test::Config::System->builder;

    unless (eval { symlink("",""); 1 }) {
        $tb->skip("symlinks are not supported on this platform");
        return undef;
    }

    $src = shift;
    if (!$src) {
        carp "Filename required";
        return undef;
    }

    $target   = shift;
    $testname = (shift || $src);
    $invert   = (shift || 0);

    my $link = readlink($src);
    if (!$link) {       # not a symlink or ENOENT, fail
        $res = 0;
    } elsif ($target) { # valid link and target is asked for
        $res = (($link eq $target) ? 1 : 0);
    } else {            # valid link and don't care about target
        $res = -l $src;
    }

    $tb->ok($invert ? !$res : $res, $testname);
}

=head2 check_dir( PATH, [STAT, DESC, INVERT] )

check_dir verifies that a directory exists.  Optionally, it can check various
attributes such as owner, group, or permissions.

  - PATH: path of the directory to check
  - STAT: a hashref of attributes to check and their desired values.  Valid keys:
        -uid    owner uid
        -gid    owner gid
        -mode   file permissions
    Each key is optional, as is the entire hash.  Note that the type need not
    be specified in -mode; it is added automatically (ie use 0700 instead of
    040700).

  - DESC: test name (optional, defaults to PATH)
  - INVERT: invert test (optional, defaults to 0.  Possible values are 0 and 1.)

Examples:
    check_dir('/var/www');
    check_dir('/home/ian', { '-uid' => scalar getpwnam('ian') } );
    check_dir('/root/', { '-uid' => 0, '-gid' => 0, '-mode' => 0700 }, '/root/ has sane permissions');
    check_dir('/home/evilbob', { }, 'Evilbobs homedir does not exist', 1);

=cut

sub check_dir {
    my %tbl = ( '-uid'  => 4,
                '-gid'  => 5,
                '-mode' => 2,
              );

    my ($path, $stat, $testname, $invert,$res);
    $path = shift;
    if (!$path) {
        carp "path required";
        return undef;
    }

    $stat     = (shift || { });
    $testname = (shift || $path);
    $invert   = (shift || 0);

    my $tb = Test::Config::System->builder;

    $res = 0;
    $res = 1 if (-d $path);     # is it a directory?

    if ($res && ref($stat) eq 'HASH') { # path is a dir and $stat was supplied
        my @attrs = stat($path);
        $attrs[2] -= 040000; # Already know the type, only matching perms
        ## Loop through each pair or until $res is false
        while ((my ($key, $val) = each(%$stat)) && $res) {
            ## Look up the key's position in the list returned from stat(),
            ##   and compare the return from stat() to the value given.
            if (exists($tbl{$key})) {
                $res = ($attrs[$tbl{$key}] == $val) ? 1 : 0;
            }
            $tb->diag("required: $key->$val, actual: $key->" . $attrs[$tbl{$key}]) unless $res;
        }
    }
    $tb->ok($invert ? !$res : $res, $testname);
}
#    $val = oct($val) if $val =~ /^0/;

=head1 AUTHOR

Ian Kilgore, C<< <iank at cpan.org> >>

=head1 BUGS

=over 4

=item * Never call check_package or check_file with untrusted input.

check_package shells out to dpkg, and check_file uses an arbitrary regexp.

=item * check_package currently only supports dpkg

=item * This module remains untested on windows and non-linux unixes

=back

Please report any bugs or feature requests to
C<bug-test-config-system at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Config-System>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Config::System

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Config-System>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Config-System>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Config-System>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Config-System>

=back

=head1 ACKNOWLEDGEMENTS

Many thanks to [naikonta] at perlmonks, for reviewing the module before release.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Ian Kilgore, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Builder::Module>

=cut

1; # End of Test::Config::System
