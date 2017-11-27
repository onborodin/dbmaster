#!/usr/local/bin/perl

use Mojo::UserAgent;
use Mojo::Util qw(dumper);
use Mojo::JSON qw(decode_json);

my $ua = Mojo::UserAgent->new(max_redirects => 5);

my $b = $ua->get("https://pgdb-msk:3001/hello")->result->body;

my $res = decode_json $b;

print $res->{'message'}."\n";
