#!/usr/local/bin/perl

use strict;
use warnings;
use utf8;

use Mojo::Server::Prefork;
use Mojo::IOLoop::Subprocess;
use Mojo::Util qw(monkey_patch b64_encode b64_decode md5_sum getopt dumper);
use Mojo::JSON qw(decode_json encode_json);

my %hash;

$hash{'dblist'}{'cdr'}{'size'} = 1200;

my $j = '';


print encode_json \%hash;
 

#EOF
