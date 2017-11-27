#!/usr/local/bin/perl

use Net::SSH::Perl;
use Data::SExpression;
use Data::Dumper;
use DBI;

use strict;


my $host = "v5.unix7.org";
my $user = "ziggi";
my $pass = "bowie2";

my $ssh = Net::SSH::Perl->new($host, 
        options => [
        "BatchMode yes",
        "RhostsAuthentication yes",
        "RSAAuthentication yes",
        "PasswordAuthentication yes",
       ]
);
$ssh->login($user, $pass);

my $cmd = "ps ax";
my ($stdout, $stderr, $exit) = $ssh->cmd($cmd);

print "$stdout" . "\n";

