#!/usr/local/bin/perl

use strict;
use warnings;
use Mojo::UserAgent;
use Mojo::JSON qw(j decode_json);
use Mojo::Util qw(dumper);

my $ua = Mojo::UserAgent->new(max_redirects => 5);

$ua->max_response_size(10737418240);

my $url = $ARGV[0];
my $data = $ARGV[1];

#exit unless $url;
#exit unless $data;

my $tx = $ua->post($url => form => {
            data => { file => $data }
});

print dumper j($tx->result->body),"\n";

#EOF
