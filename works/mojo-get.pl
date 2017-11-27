#!/usr/local/bin/perl

use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new(max_redirects => 5);

#my $tx = $ua->get(
#    'http://www.github.com/kraih/mojo/tarball/master'
#    => {Accept => '*/*'} =>  form => { a => "12" }
##    => {Accept => '*/*'} => json => {a => 'b'}
#);

#$tx->result->content->asset->move_to('mojo.tar.gz');


#my $tx = $t->tx(POST => 'http://example.com' => form => {
#  a      => 'b',
#  c      => 'd',
#  mytext => {
#    file => '/foo.txt',
#    content        => 'lalala',
#    filename       => 'foo.txt',
#    'Content-Type' => 'text/plain'
#  }
#});

use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new(max_redirects => 5);
$ua->max_response_size(10737418240);

my $tx = $ua->post(
    'http://localhost:3000/store/put' =>
        form => {
            data => {
                file => '/data/oracle-pm6-v907897-01.zip',
#                file => '/foo.txt',
               filename       => 'some.bin',
#               'Content-Type' => 'text/plain'
            }
        }
);


#EOF
