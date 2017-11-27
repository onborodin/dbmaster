#!/usr/local/bin/perl

use Mojo::UserAgent;
use Mojo::JSON qw(encode_json decode_json);
use Mojo::Util qw(dumper);


my $ua = Mojo::UserAgent->new(max_redirects => 5);
my $tx = $ua->get('http://127.0.0.1:3001/db/list');

my $res = decode_json($tx->result->body);

my $list = $res->{'list'};
my @list = @{$list};

#foreach my $row (@{$list}) {
#    my %r = %{$row};
#    print $r{'name'}." ". $r{'size'}."\n";
#}

$tx = $ua->get('http://127.0.0.1:3001/hello');
$res = decode_json($tx->result->body);
print "agent alive\n" if  $res->{'message'} eq 'hello';


#EOF
