#!/usr/bin/env perl

package aAgentI;

use strict;
use warnings;
use Mojo::UserAgent;
use Mojo::JSON qw(encode_json decode_json);
use Mojo::Util qw(dumper);

sub new {
    my ($class, $host, $login, $password) = @_;
    my $ua = Mojo::UserAgent->new;
    my $self = {
        host => $host,
        login => $login,
        password => $password,
        port => '8185',
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

sub db_list {
    my $self = shift;
    $self->rpc('/db/list');
}

sub db_profile {
    my ($self, $name) = @_;
    $self->rpc('/db/profile', name => $name);
}

sub db_create {
    my ($self, $name) = @_;
    $self->rpc('/db/create', name => $name);
}

sub db_drop {
    my ($self, $name) = @_;
    $self->rpc('/db/drop', name => $name);
}

sub db_rename {
    my ($self, $name, $new_name) = @_;
    $self->rpc('/db/rename', name => $name, new_name => $new_name);
}

sub db_owner {
    my ($self, $name) = @_;
    $self->rpc('/db/drop', name => $name);
}


sub user_list {
    my $self = shift;
    $self->rpc('/user/list');
}

sub user_profile {
    my ($self, $name) = @_;
    $self->rpc('/user/profile', name => $name);
}

sub user_create {
    my ($self, $name, $password) = @_;
    $self->rpc('/user/create', name => $name, password => $password);
}

sub user_drop {
    my ($self, $name) = @_;
    $self->rpc('/user/drop', name => $name);
}

sub user_rename {
    my ($self, $name, $new_name) = @_;
    $self->rpc('/user/rename', name => $name, new_name => $new_name);
}

sub user_password {
    my ($self, $name, $password) = @_;
    $self->rpc('/user/password', name => $name, password => $password);
}

sub db_dump {
    my ($self, $name, $store, $login, $password, $cb, $job_id, $magic) = @_;
    $self->rpc('/db/dump',
                        name => $name,
                        store => $store,
                        login => $login,
                        password => $password,
                        cb => $cb,
                        job_id => $job_id,
                        magic => $magic);
}

sub db_restore {
    my $self = shift;
    return undef;
}

1;

use strict;
use warnings;
use Mojo::Util qw(dumper);


my $a = aAgentI->new("127.0.0.1", "user", "password");
#print dumper $a->rpc('/hello');

print dumper $a->db_list;
print dumper $a->db_profile('asterisk_copy');
print dumper $a->db_create('asterisk_copy');
print dumper $a->db_create('asterisk_copy_2');
print dumper $a->db_profile('asterisk_copy_2');
print dumper $a->db_drop('asterisk_copy_2');
print dumper $a->db_profile('asterisk_copy_2');

print dumper $a->user_profile('asterisk');
print dumper $a->user_create('asterisk_2', '123456');
print dumper $a->user_profile('asterisk_2');
print dumper $a->user_rename('asterisk_2', 'asterisk_222');
print dumper $a->user_profile('asterisk_222');
print dumper $a->user_drop('asterisk_222');

my $list = $a->db_list->{list};

foreach my $pro (@$list) {
    my $name = $pro->{name};
    print dumper $a->db_dump($name, 'thx.unix7.org', 'login', 'password', 'thx.unix7.org', '123', 'magic');
}

#print dumper $a->db_dump('asterisk_copy', 'thx.unix7.org', 'login', 'password', 'thx.unix7.org', '123', 'magic');

#EOF

