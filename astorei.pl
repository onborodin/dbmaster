#!/usr/bin/env perl

package aStoreI;

use strict;
use warnings;
use Mojo::UserAgent;
use Mojo::JSON qw(encode_json decode_json);
use Mojo::Util qw(dumper);

sub new {
    my ($class, $host, $login, $password) = @_;
    my $ua = Mojo::UserAgent->new;
    $ua->max_response_size(10*1024*1024*1024);
    $ua->inactivity_timeout(60);
    $ua->connect_timeout(60);
    $ua->request_timeout(60*60);
    my $self = {
        host => $host,
        login => $login,
        password => $password,
        port => '8184',
        ua => $ua
    };
    bless $self, $class;
    return $self;
}

sub ua {
    my ($self, $ua) = @_;
    return $self->{ua} unless $ua;
    $self->{ua} = $ua;
    $self;
}

sub host {
    my ($self, $host) = @_;
    return $self->{host} unless $host;
    $self->{host} = $host;
    $self;
}

sub login {
    my ($self, $login) = @_;
    return $self->{login} unless $login;
    $self->{login} = $login;
    $self;
}

sub password {
    my ($self, $password) = @_;
    return $self->{password} unless $password;
    $self->{password} = $password;
    $self;
}

sub port {
    my ($self, $port) = @_;
    return $self->{port} unless $port;
    $self->{port} = $port;
    $self;
}


sub rpc {
    my ($self,  $call, %args) = @_;
    return undef unless $call;
    return undef unless $call =~ /^\//;

    my $host = $self->host;
    my $login = $self->login;
    my $password = $self->password;
    my $port = $self->port;

    my $url = "http://$login:$password\@$host:$port$call";
    $url .= "?" if %args;
    foreach my $key (sort keys %args) {
        my $value = $args{$key};
        next unless $value;
        $url .= "&$key=$value";
    }

    $url =~ s/\?&/\?/;
    my $tx = $self->ua->get($url);
    my $res = $tx->result->body;
    my $j = decode_json($res);
    return $j if $j;
    undef;
}


sub alive {
    my $self = shift;
    my $res = $self->rpc('/hello');
    return 1 if  $res->{'message'} eq 'hello';
    return undef;
}

sub list {
    my $self = shift;
    $self->rpc('/list');
}

sub profile {
    my ($self, $name) = @_;
    $self->rpc('/profile', name => $name);
}

sub delete {
    my ($self, $name) = @_;
    $self->rpc('/delete', name => $name);
}

sub get {
    my ($self, $name, $dir) = @_;

    return undef unless $dir;
    return undef unless -w $dir;

    my $host = $self->host;
    my $login = $self->login;
    my $password = $self->password;
    my $port = $self->port;

    $ENV{MOJO_TMPDIR} = $dir;

    my $tx = $self->ua->get("http://$login:$password\@$host:$port/get?name=$name");
    my $res = $tx->result;

    my $type = $res->headers->content_type || '';
    my $disp = $res->headers->content_disposition || '';
    my $file = "$dir/$name";

    if ($type =~ /name=/ or $disp =~ /filename=/) {
        my ($filename) = $disp =~ /filename=\"(.*)\"/;
        rename $file, "$file.bak" if -r $file;
        $res->content->asset->move_to($file);
    }
    return undef unless -r $file;
    $file;
}

sub put {
    my ($self, $file) = @_;

    return undef unless $file;
    return undef unless -r $file;

    my $host = $self->host;
    my $login = $self->login;
    my $password = $self->password;
    my $port = $self->port;

    my $url = "http://$login:$password\@$host:$port/put";
    my $tx = $self->ua->post($url => form => {data => { file => $file } });
    my $res = $tx->result;

    my $type = $res->headers->content_type || '';
    return undef unless $type =~ 'application/json';
    my $body = '';
    eval { $body = $res->body; };

    my $j = decode_json($body);
    $j->{success};
}

1;

use strict;
use warnings;
use Mojo::Util qw(dumper);

my $s = aStoreI->new("pgdb-msk.lazurit.us", "user", "password");

print dumper $s->list;
print dumper $s->put('data.bin');
print dumper $s->profile('data.bin');
print dumper $s->get('data.bin', '.');
print dumper $s->delete('data.bin');
print dumper $s->profile('data.bin');

#EOF

