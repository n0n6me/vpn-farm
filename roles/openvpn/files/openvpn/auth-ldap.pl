#!/usr/local/bin/perl

# Copyright (c) 2014, analogrithems
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# OpenVPN LDAP AUTHENTICATON
#   This script is based off the PAM example auth system but slightly
#   modified for use with LDAP since the openvpn-auth-ldap is currently broken for freebsd :(
#   details here: https://bugs.freebsd.org/bugzilla/show_bug.cgi?format=multiple&id=190497
#   This is just simple perl glue for use in the mean time.
#


# SCRIPT OPERATION
#   Return success or failure status based on whether or not a
#   given username/password authenticates using LDAP.
#   Caller should write username/password as two lines in a file
#   which is passed to this script as a command line argument.
#   Configuration options are read from auth-ldap.conf in the same directory

# CAVEATS
#   * Requires Authen::Simple::LDAP module, which may also
#     require ldap-client libs
#   * Requires Config::Simple for a simple config filee
#   * May need to be run as root in order to
#     access username/password file.

# NOTES
#   * This script is provided mostly as a demonstration of the
#     --auth-user-pass-verify script capability in OpenVPN.

use Authen::Simple::LDAP;
use Config::Simple;
use POSIX;

# Get username/password from file

if ($ARG = shift @ARGV) {
    if (!open (UPFILE, "<$ARG")) {
    print "Could not open username/password file: $ARG\n";
    exit 1;
    }
} else {
    print "No username/password file specified on command line\n";
    exit 1;
}

$username = <UPFILE>;
$password = <UPFILE>;

if (!$username || !$password) {
    print "Username/password not found in file: $ARG\n";
    exit 1;
}

chomp $username;
chomp $password;

close (UPFILE);

# Initialize Auth LDAP
$cfg = new Config::Simple('auth-ldap.conf');
%Config = $cfg->vars();

for $_key ( keys %Config ) {
    #strip the default from keys
    $_old = $_key;
    $_key =~ s/default\.//ig;
    $Config{$_key} = $Config{$_old};
    delete $Config{$_old};
}

my $ldap = Authen::Simple::LDAP->new( %Config );

if ( $ldap->authenticate( $username, $password ) ) {
    # successfull authentication
    exit 0;
}else{
    print "Auth '$username' failed\n";
    exit 1;
}
