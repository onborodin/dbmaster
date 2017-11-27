#!/usr/bin/env perl

package PGmaster::Model;

use strict;
use warnings;
use File::stat;
use DBI;
use Mojo::UserAgent;
use Mojo::JSON qw(encode_json decode_json);
use Mojo::Util qw(md5_sum dumper);
use Socket;
use POSIX;


sub new {
    my ($class, $app, $dbhost, $dbuser, $dbpasswd, $dbname) = @_;
    my $self = {
        app => $app,
        dbhost => $dbhost,
        dsn => "dbi:Pg:dbname=$dbname;host=$dbhost",
        dbuser => $dbuser,
        dbpasswd => $dbpasswd,
        dbname => $dbname
    };
    bless $self, $class;
    return $self;
}

sub dbuser {
    return shift->{dbuser};
}

sub dbpasswd {
    return shift->{dbpasswd};
}

sub dsn {
    return shift->{dsn};
}

sub dbhost {
    return shift->{dbhost};
}

sub app {
    return shift->{app};
}

sub hostnameAlive {
    my ($self, $hostname) = @_;
    return undef unless gethostbyname($hostname);
    return 1;
}

sub parseLabel {
    my ($self, $label) = @_;
    return undef unless $label;

    $label =~ s/.sqlz$//;

    my ($dbname, $Y, $M, $D, $h, $m, $s, $tz, $host) =
        $label =~ /([_a-z0-9]{1,64})--([0-9]{4})([0-9]{2})([0-9]{2})-([0-9]{2})([0-9]{2})([0-9]{2})-([A-Z0-9\+]{2,4})--([_\-a-zA-Z0-9\.]{1,64})/g;

    my %data;
    $data{'dbname'} = $dbname;
    $data{'timestamp'} = "$Y-$M-$D $h:$m:$s $tz";
    $data{'datetime'} = "$Y-$M-$D $h:$m:$s";
    $data{'tz'} = "$tz";
    $data{'source'} = $host;
    return \%data;
}

sub timestamp {
    my ($self, $timenum) = shift;
    $timenum = time unless $timenum;
    return strftime("%Y-%m-%d %H:%M:%S %Z", localtime($timenum));
}

sub currSec {
    my $self = shift;
    return strftime("%S", localtime(time));
}

sub currTime {
    my $self = shift;
    my $time = time;
    my %time;
    $time{sec} = strftime("%S", localtime($time));
    $time{min} = strftime("%M", localtime($time));
    $time{hour} = strftime("%H", localtime($time));
    $time{mday} = strftime("%d", localtime($time));
    $time{month} = strftime("%m", localtime($time));
    $time{yarth} = strftime("%Y", localtime($time));
    $time{wday} = strftime("%u", localtime($time));
    return \%time;
}

sub sizeHR {
    my ($self, $size) = @_;
    return $size if $size < 1024;
    return int($size/1024+0.5)."k" if ($size < 1024*1024 && $size > 1024);
    return int($size/(1024*1024)+0.5)."M" if ($size < 1024*1024*1024 && $size > 1024*1024);
    return int($size/(1024*1024*1024)+0.5)."G" if ($size < 1024*1024*1024*1024 && $size > 1024*1024*1024);
}

sub sizeWP {
    my ($self, $size) = @_;
    my $out = $size;
    $out =~ s/(\d{9})$/.$1/g if $size > 1000*1000*1000;
    $out =~ s/(\d{6})$/.$1/g if $size > 1000*1000;
    $out =~ s/(\d{3})$/.$1/g if $size > 1000;
    return $out;
}

sub sizeM {
    my ($self, $size) = @_;
    return int($size/(1024*1024)+0.5);
}

sub stripSec {
    my ($self, $s) = @_;
    my $a = substr $s, 0, 16;
    $a =~ s/\//-/g;
    return $a;
}

#-------------------
#--- AGENT MODEL ---
#-------------------

sub agentList {
    my ($self, $id)  = @_;
    my $where = '';
    $where = "where id = $id" if $id;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "select * from agent $where order by hostname;";
#    my $query = "select a.hostname, a.username, a.password, sum(d.size) as sum, count(d.name) as count
#                 from agent a, db d
#                    where a.id = d.agentid group by a.hostname, a.username,a.password
#                    order by a.hostname;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;

    my @list;
    while (my $row = $sth->fetchrow_hashref) {
        push @list, $row;
    }
    $sth->finish;
    $dbi->disconnect;
    return \@list;
}

sub agentExist {
    my ($self, $hostname)  = @_;
    return undef unless $hostname;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "select id from agent where hostname = '$hostname' limit 1;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my $row = $sth->fetchrow_hashref;
    $sth->finish;
    $dbi->disconnect;
    my $id = $row->{'id'};
    return $id if $id;
    return undef;
}

sub agentHostname {
    my ($self, $id)  = @_;
    return undef unless $id;

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "select hostname from agent where id = $id limit 1;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my $row = $sth->fetchrow_hashref;
    $sth->finish;
    $dbi->disconnect;

    my $hostname = $row->{'hostname'};
    return $hostname if $hostname;
    return undef;
}

sub agentProfile {
    my ($self, $id)  = @_;
    return undef unless $id;

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;

    my $query = "select * from agent where id = $id limit 1;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my $row = $sth->fetchrow_hashref;

    $sth->finish;
    $dbi->disconnect;

    return $row if $row;
    return undef;
}

sub agentInfo {
    my ($self, $id)  = @_;
    return undef unless $id;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;

    my $query = "select sum(d.size) as sum , count(d.name) as count
                    from agent a, db d
                    where a.id = d.agentid and a.id = $id;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my $row = $sth->fetchrow_hashref;

    $sth->finish;
    $dbi->disconnect;

    $row->{'sum'} ||= 0;
    return $row if $row;
    return undef;
}

sub agentNextID {
    my $self = shift;

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "select id from agent order by id desc limit 1;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my $row = $sth->fetchrow_hashref;
    my $id = $row->{'id'};

    $sth->finish;
    $dbi->disconnect;
    $id++;

    return $id;
}

sub agentAdd {
    my ($self, $hostname, $username, $password) = @_;
    return undef unless $hostname;
    return undef unless $username;
    return undef unless $password;

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
         or return undef;
    my $id = $self->agentNextID;
    my $query = "insert into agent (id, hostname, username, password)
                    values ($id, '$hostname', '$username', '$password');";
    my $rows = $dbi->do($query) or return undef;
    $dbi->disconnect;

    return $id if $rows*1 > 0;
    return undef;
}

sub agentDelete {
    my ($self, $id) = @_;
    return undef unless $id;

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "delete from agent where id = $id;";
    my $rows = $dbi->do($query) or return undef;

    $dbi->disconnect;
    return $rows*1;
}

sub agentConfig {
    my ($self, $id, $hostname, $username, $password) = @_;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "update agent set
                    hostname = '$hostname',
                    username = '$username',
                    password = '$password'
                    where id = $id;";
    my $rows = $dbi->do($query) or return undef;
    $dbi->disconnect;
    return $rows*1;
}

sub agentAlive {
    my ($self, $id) = @_;
    return undef unless $id;
    my $hostname = $self->agentHostname($id);
    return undef unless $hostname;
    my $ua = Mojo::UserAgent->new;
    $ua = $ua->connect_timeout(5);


    my $tx = $ua->get("https://$hostname:3001/hello");
    my $body;
    eval {
        $body = $tx->result->body;
    };
    do { $self->app->log->info("agentAlive: $@");  return undef; } if $@;
    return undef unless $body;
    my $res = decode_json $body;
    return 1 if $res->{'message'} eq 'hello';
    return undef;
}

sub agentDBList {
    my ($self, $id) = @_;
    return undef unless $id;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "select * from db where agentid = $id order by name;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my @list;
    while (my $row = $sth->fetchrow_hashref) {
        push @list, $row;
    }
    $sth->finish;
    $dbi->disconnect;
    return \@list;
}

sub agentDBUpdate {
    my ($self, $id) = @_;
    return undef unless $id;
    my $agentProfile = $self->agentProfile($id) or return undef;

    my $hostname = $agentProfile->{'hostname'} || 'undef';
    my $username = $agentProfile->{'username'} || 'undef';
    my $password = $agentProfile->{'password'} || 'password';

    my $ua = Mojo::UserAgent->new(max_redirects => 2) or return undef;
    $ua = $ua->connect_timeout(5);
    my $tx = $ua->get("https://$username:$password\@$hostname:3001/db/list");

    my $res;
    eval { $res = decode_json($tx->result->body); };
    return undef if $@;

    my $dblist = $res->{'dblist'};

    return undef unless $dblist;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "delete from db where agentid = $id;";
    my $rows = $dbi->do($query) or return undef;
    return undef unless $rows;
    foreach my $rec (@{$dblist}) {
        my $dbname = $rec->{'name'} || 'undef';
        my $dbsize = $rec->{'size'} || 1;
        my $dbowner = $rec->{'owner'} || 'undef';
        my $numbackends = $rec->{'numbackends'} || 0;
        my $query = "insert into db (agentid, name, size, owner, type, numbackends) values
                    ($id, '$dbname',  $dbsize, '$dbowner', 'pgsql', $numbackends);";
        my $rows = $dbi->do($query);
    }
    $dbi->disconnect;
    return $dblist;
}

#-------------------
#--- STORE MODEL ---
#-------------------

sub storeHostname {
    my ($self, $id)  = @_;
    return undef unless $id;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "select hostname from store where id = $id limit 1;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my $row = $sth->fetchrow_hashref;
    $sth->finish;
    $dbi->disconnect;
    my $hostname = $row->{'hostname'};
    return $hostname if $hostname;
    return undef;
}

sub storeProfile {
    my ($self, $id)  = @_;
    return undef unless $id;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "select * from store where id = $id limit 1;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my $row = $sth->fetchrow_hashref;
    $sth->finish;
    $dbi->disconnect;
    return $row if $row;
    return undef;
}

sub storeInfo {
    my ($self, $id)  = @_;
    return undef unless $id;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "select sum(d.size) as sum , count(d.name) as count
                    from store s, data d
                    where s.id = d.storeid and s.id = $id;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my $row = $sth->fetchrow_hashref;
    $sth->finish;
    $dbi->disconnect;
    $row->{'sum'} ||= 0;
    return $row if $row;
    return undef;
}

sub storeAlive {
    my ($self, $id) = @_;
    return undef unless $id;
    my $hostname = $self->storeHostname($id);
    return undef unless $hostname;

    my $ua = Mojo::UserAgent->new;
    $ua = $ua->connect_timeout(5);
    my $tx = $ua->get("https://$hostname:3002/hello");

    my $body;
    eval { $body = $tx->result->body; };
    do { $self->app->log->info("storeAlive: $@"); return undef; } if $@;
    return undef unless $body;

    my $res = decode_json $body;

    return 1 if $res->{'message'} eq 'hello';
    return undef;
}

sub storeList {
    my ($self, $id)  = @_;
    my $where = '';
    $where = "where id = '$id'" if $id;

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd);
    my $query = "select * from store $where order by hostname;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;

    my @list;
    while (my $row = $sth->fetchrow_hashref) {
        push @list, $row;
    }

    $sth->finish;
    $dbi->disconnect;

    return \@list;
}

sub storeExist {
    my ($self, $hostname)  = @_;
    return undef unless $hostname;

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "select id from store where hostname = '$hostname' limit 1;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my $row = $sth->fetchrow_hashref;

    $sth->finish;
    $dbi->disconnect;

    my $id = $row->{'id'};
    return $id if $id;
    return undef;
}

sub storeNextID {
    my $self = shift;

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd);
    my $query = "select id from store order by id desc limit 1;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my $row = $sth->fetchrow_hashref;
    my $id = $row->{'id'};
    $id++;
    $sth->finish;
    $dbi->disconnect;
    return $id;
}

sub storeAdd {
    my ($self, $hostname, $username, $password) = @_;
    return undef unless $hostname;
    return undef unless $username;
    return undef unless $password;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $id = $self->storeNextID;
    my $query = "insert into store (id, hostname, username, password)
                    values ($id, '$hostname', '$username', '$password');";
    my $rows = $dbi->do($query) or return undef;
    $dbi->disconnect;
    return $id if $rows*1 > 0;
    return undef;
}

sub storeDelete {
    my ($self, $id) = @_;

    return undef unless $id;

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "delete from store where id = $id;";
    my $rows = $dbi->do($query) or return undef;

    $dbi->disconnect;
    return $rows*1;
}

sub storeConfig {
    my ($self, $id, $hostname, $username, $password) = @_;

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "update store set
                    hostname = '$hostname',
                    username = '$username',
                    password = '$password'
                    where id = $id;";
    my $rows = $dbi->do($query) or return undef;
    $dbi->disconnect;
    return $rows*1;
}

sub storeDataList {
    my ($self, $id) = @_;
    return undef unless $id;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;

    my $query = "select * from data where storeid = $id order by name;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my @list;
    while (my $row = $sth->fetchrow_hashref) {
        push @list, $row;
    }

    $sth->finish;
    $dbi->disconnect;

    return \@list;
}

sub storeDataUpdate {
    my ($self, $id) = @_;
    return undef unless $id;
    my $storeProfile = $self->storeProfile($id) or return undef;

    my $hostname = $storeProfile->{'hostname'} || 'undef';
    my $username = $storeProfile->{'username'} || 'undef';
    my $password = $storeProfile->{'password'} || 'password';

    my $ua = Mojo::UserAgent->new(max_redirects => 2) or return undef;
    $ua = $ua->connect_timeout(5);
    my $tx = $ua->get("https://$username:$password\@$hostname:3002/store/list");

    my $res = undef;
    eval { $res = decode_json($tx->result->body); };
    return undef if $@;

    my $free = $res->{'free'} || 0;
    my $datalist = $res->{'datalist'} || undef;

    return undef unless $datalist;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "delete from data where storeid = $id;";
    my $rows = $dbi->do($query) or return undef;
    return undef unless $rows;

    $query = "update store set free = $free where id = $id;";
    $rows = $dbi->do($query) or return undef;
    return undef unless $rows;

    my @list;
    foreach my $rec (@{$datalist}) {
        my $dataname = $rec->{'name'};
        my $datasize = $rec->{'size'};
        my $datamtime = $rec->{'mtime'};

        # Dataname pattern for dumps dbname--timestamp--sourcehost.ext
        next unless $dataname =~ m/.+--.+--.+\.(sqlz|sql|sql.gz|sql.xz)/;

        $self->app->log->debug("Parse label $dataname");
        my $label = $self->app->model->parseLabel($dataname);
        my $dbname = $label->{'dbname'} || 'undef';
        my $source = $label->{'source'} || 'undef';
        my $stamp = $label->{'timestamp'} || '1970-01-01 00:00:00 UTC';
        my $datetime = $label->{'datetime'} || '1970-01-01 00:00:00';
        my $tz = $label->{'tz'} || 'UND';
        $self->app->log->debug("Parse label $dataname: dbname=$dbname, stamp=$stamp");

        my $query = "insert into data (storeid, name, size, mtime, type, dbname, source, stamp, datetime, tz) values
                    ($id, '$dataname',  $datasize, '$datamtime', 'pgsql', '$dbname', '$source', '$stamp', '$datetime', '$tz');";
        my $rows = $dbi->do($query) or return undef;
        push @list, $rec;
    }
    $dbi->disconnect;
    return \@list;
}

sub storeFree {
    my ($self, $id)  = @_;
    return undef unless $id;

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;

    my $query = "select free from store where id = $id limit 1;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my $row = $sth->fetchrow_hashref;

    $sth->finish;
    $dbi->disconnect;

    my $free = $row->{'free'};

    return $free if $free;
    return undef;
}

#---------------
#--- XXXXXXX ---
#---------------

sub dataList {
    my $self = shift;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "select s.hostname as store, d.* from data d, store s where s.id = d.storeid order by d.dbname;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my @list;
    while (my $row = $sth->fetchrow_hashref) {
        push @list, $row;
    }
    $sth->finish;
    $dbi->disconnect;
    return \@list;
}

#-----------------
#--- JOB MODEL ---
#-----------------

sub jobCreate {
    my ($self, @args) = @_;

    my $id = $self->jobNextID;

    my $begin = strftime("%Y-%m-%d %H:%M:%S %Z", localtime(time));
    my $stop = '1970-01-01 00:00:00 UTC';
    my $type = "undef";
    my $author = "undef";
    my $sourceid = 0;
    my $destid = 0;
    my $status = "undef";
    my $error = "undef";
    my $message = "Job record created";
    my $magic = md5_sum(localtime(time));

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
         or return undef;
    my $query = "insert into job (id, begin, stop, author, type, sourceid, destid, status, error, message, magic)
                    values ($id, '$begin', '$stop', '$author', '$type', $sourceid, $destid, '$status', '$error', '$message', '$magic');";
    my $rows = $dbi->do($query) or return undef;
    $dbi->disconnect;
    return $id if $rows*1 > 0;
    return undef;
}

sub jobList {
    my $self = shift;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "select id,
                    to_char(begin, 'YYYY-MM-DD HH24:MI:SS TZ') as begin,
                    to_char(stop, 'YYYY-MM-DD HH24:MI:SS TZ') as stop,
                    author, type, sourceid, destid, status, error, message, magic from job
                        order by id desc limit 100;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my @list;
    while (my $row = $sth->fetchrow_hashref) {
        push @list, $row;
    }
    $sth->finish;
    $dbi->disconnect;
    return \@list;
}

sub jobNextID {
    my $self = shift;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "select id from job order by id desc limit 1;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my $row = $sth->fetchrow_hashref;
    my $id = $row->{'id'};
    $id++;
    $sth->finish;
    $dbi->disconnect;
    return $id;
}

sub jobExist {
    my ($self, $id)  = @_;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "select id from job where id = $id limit 1;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my $row = $sth->fetchrow_hashref;
    $sth->finish;
    $dbi->disconnect;
    $id = $row->{'id'};
    return $id if $id;
    return undef;
}

sub jobUpdate {
    my ($self, $id, %args) = @_;

    return undef unless $id;
    return undef unless $self->jobExist($id);

    my $jobProfile = $self->jobProfile($id);
    my $args = \%args;

    my $begin = $args->{'begin'} || $jobProfile->{'begin'};
    my $stop = $args->{'stop'} || $jobProfile->{'stop'};
    my $type = $args->{'type'} || $jobProfile->{'type'};
    my $author = $args->{'author'} || $jobProfile->{'author'};
    my $sourceid = $args->{'sourceid'} || $jobProfile->{'sourceid'};
    my $destid = $args->{'destid'} || $jobProfile->{'destid'};

    my $status = $args->{'status'} || $jobProfile->{'status'};
    my $error = $args->{'error'} || $jobProfile->{'error'};
    my $message = $args->{'message'} || $jobProfile->{'message'};

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;

    my $query = "update job set
                    begin = '$begin',
                    stop = '$stop',
                    author = '$author',
                    type = '$type',
                    sourceid = $sourceid,
                    destid = $destid,
                    status = '$status',
                    error = '$error',
                    message = '$message'
                        where id = $id;";

    my $rows = $dbi->do($query) or return undef;
    $dbi->disconnect;
    return $id if $rows;
    return undef;
}

sub jobDelete {
    my ($self, $id) = @_;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;

    my $query = "delete from job where id = $id;";
    my $rows = $dbi->do($query) or return undef;

    $dbi->disconnect;

    return $rows if $rows;
    return undef;
}

sub jobProfile {
    my ($self, $id)  = @_;

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;

    my $query = "select id, to_char(begin, 'YYYY-MM-DD HH24:MI:SS TZ') as begin,
                    to_char(stop, 'YYYY-MM-DD HH24:MI:SS TZ') as stop,
                    author, type, sourceid, destid, status, error, message, magic from job where id = $id limit 1;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my $row = $sth->fetchrow_hashref;

    $sth->finish;
    $dbi->disconnect;

    return $row if $row;
    return undef;
}

sub jobCB {
    my ($self, $req)  = @_;

    my $jobID = $req->param('jobid');
    my $magic = $req->param('magic');

    return undef unless $jobID;
    return undef unless $magic;

    my $jobProfile = $self->jobProfile($jobID);

    my $error = $req->param('error');
    my $status = $req->param('status');
    my $message = $req->param('message');

    $self->jobUpdate($jobID, error => $error, stop => $self->timestamp) if $error;
    $self->jobUpdate($jobID, status => $status, stop => $self->timestamp) if $status;
    $self->jobUpdate($jobID, message => $message, stop => $self->timestamp) if $message;

    return 1;
}
#----------------------
#--- SCHEDULE MODEL ---
#----------------------

sub scheduleList {
    my ($self, $id)  = @_;
    my $where = '';
    $where = "where id = $id" if $id;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "select * from schedule $where order by id;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;

    my @list;
    while (my $row = $sth->fetchrow_hashref) {
        push @list, $row;
    }
    $sth->finish;
    $dbi->disconnect;
    return \@list;
}

sub scheduleProfile {
    my ($self, $id)  = @_;
    return undef unless $id;

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "select * from schedule where id = $id limit 1;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my $row = $sth->fetchrow_hashref;

    $sth->finish;
    $dbi->disconnect;

    return $row if $row;
    return undef;
}

sub scheduleNextID {
    my $self = shift;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "select id from schedule order by id desc limit 1;";
    my $sth = $dbi->prepare($query);
    my $rows = $sth->execute;
    my $row = $sth->fetchrow_hashref;
    my $id = $row->{'id'};
    $id++;
    $sth->finish;
    $dbi->disconnect;
    return $id;
}

sub scheduleAdd {
    my ($self, $type, $sourceID, $destID, $subject, $mday, $wday, $hour, $min) = @_;

    $self->app->log->debug("--- scheduleAdd: $type, $sourceID, $destID, $subject, $mday, $wday, $hour, $min");

    return undef unless $type;
    return undef unless $sourceID;
    return undef unless $destID;
    return undef unless $subject;
    return undef unless $mday;
    return undef unless $wday;
    return undef unless $hour;
    return undef unless $min;

    my $id = $self->scheduleNextID;
    return undef unless $id;

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
         or return undef;
    my $query = "insert into schedule (id, type, sourceid, destid, subject, mday, wday, hour, min)
                    values ($id, '$type', $sourceID, $destID, '$subject', '$mday', '$wday', '$hour', '$min');";
    my $rows = $dbi->do($query) or return undef;
    $dbi->disconnect;

    return $id if $rows*1 > 0;
    return undef;
}


sub periodExpand {
    my ($self, $def, $limit, $start) = @_;
    $limit = 100 unless defined $limit;
    $start = 1 unless defined $start;
    my @list = split ',', $def;
    my @out;
    my %n;
    foreach my $sub (@list) {
        if (my ($num) = $sub =~ m/^(\d+)$/ ) {
                next if $num < $start;
                next if $num > $limit;
                push @out, $num unless $n{$num};
                $n{$num} = 1;
        }
        elsif (my ($begin, $end) = $sub =~ /^(\d+)[-. ]+(\d+)$/) {
            foreach my $num ($begin..$end) {
                next if $num < $start;
                next if $num > $limit;
                push @out, $num unless $n{$num};
                $n{$num} = 1;
            }
        }
        elsif (my ($inc) = $sub =~ /^[*]\/(\d+)$/) {
            my $num = $start;
            while ($num <= $limit) {
                next if $num < $start;
                push @out, $num unless $n{$num};
                $num += $inc;
            }
        }
        elsif ($sub =~ /^[*]$/) {
            my $num = $start;
            my $inc = 1;
            while ($num <= $limit) {
                next if $num < $start;
                next if $num > $limit;
                push @out, $num unless $n{$num};
                $num += $inc;
            }
        }
    }
    @out = sort { $a <=> $b } @out;
    return \@out
}

sub periodCompact {
    my ($self, $list) = @_;
    my %n;
    my $out;
    foreach my $num (@{$list}) { $n{$num} = 1; }
    foreach my $num (sort { $a <=> $b } (keys %n)) {
        $out .= $num."-" if $n{$num+1} && not $n{$num-1};
        $out .= $num."," unless $n{$num+1};
    }
    $out =~ s/,$//;
    return $out;
}

sub periodMatch {
    my ($self, $num, $list) = @_;
    foreach my $elem (@{$list}) {
        return 1 if $num == $elem;
    }
    return undef;
}

#-----------------
#--- MODEL END ---
#-----------------
1;

#==================
#------------------
#--- CONTROLLER ---
#------------------
#==================

package PGmaster::Controller;

use utf8;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(md5_sum dumper);
use Mojo::JSON qw(encode_json decode_json);
use Apache::Htpasswd;

sub hello {
    my $self = shift;
    $self->render(template => 'hello');
}

#------------------
#--- AGENT CONT ---
#------------------

sub agentList {
    my $self = shift;
    $self->render(template => 'agentList');
}

sub agentAdd {
    my $self = shift;
    $self->render(template => 'agentAdd', req => $self->req);
}

sub agentConfig {
    my $self = shift;
    $self->render(template => 'agentConfig', req => $self->req);
}

sub agentDelete {
    my $self = shift;
    $self->render(template => 'agentDelete', req => $self->req);
}

sub agentDBList {
    my $self = shift;
    my $id = $self->req->param('id');
    $self->render(template => 'agentDBList', req => $self->req);
}

sub agentDBCreate {
    my $self = shift;
    $self->render(template => 'agentDBCreate', req => $self->req);
}

sub agentDBDrop {
    my $self = shift;
    $self->render(template => 'agentDBDrop', req => $self->req);
}

sub agentDBRename {
    my $self = shift;
    $self->render(template => 'agentDBRename', req => $self->req);
}

sub agentDBCopy {
    my $self = shift;
    $self->render(template => 'agentDBCopy', req => $self->req);
}

sub agentDBDump {
    my $self = shift;
    $self->render(template => 'agentDBDump', req => $self->req);
}

sub agentDBRestore {
    my $self = shift;
    $self->render(template => 'agentDBRestore', req => $self->req);
}

#------------------
#--- STORE CONT ---
#------------------

sub storeList {
    my $self = shift;
    $self->render(template => 'storeList');
}

sub storeAdd {
    my $self = shift;
    $self->render(template => 'storeAdd', req => $self->req);
}

sub storeConfig {
    my $self = shift;
    $self->render(template => 'storeConfig', req => $self->req);
}

sub storeDelete {
    my $self = shift;
    $self->render(template => 'storeDelete', req => $self->req);
}

sub storeDataList {
    my $self = shift;
    $self->render(template => 'storeDataList', req => $self->req);
}

sub storeDataDelete {
    my $self = shift;
    $self->render(template => 'storeDataDelete', req => $self->req);
}

sub storeDataDownload {
    my $self = shift;
    $self->render(template => 'storeDataDownload', req => $self->req);
}


#-------------
#--- XXXXX ---
#-------------

sub dataList {
    my $self = shift;
    $self->render(template => 'dataList', req => $self->req);
}

#----------------
#--- JOB CONT ---
#----------------

sub jobList {
    my $self = shift;
    $self->render(template => 'jobList', req => $self->req);
}

sub jobCB {
    my $self = shift;
    $self->app->model->jobCB($self->req);
    $self->render(json => { responce => 'success' } );
}

#---------------------
#--- SCHEDULE CONT ---
#---------------------

sub scheduleList {
    my $self = shift;
    $self->render(template => 'scheduleList', req => $self->req);
}

sub scheduleAdd {
    my $self = shift;
    $self->render(template => 'scheduleAdd', req => $self->req);
}

sub scheduleDelete {
    my $self = shift;
    $self->render(template => 'scheduleDelete', req => $self->req);
}

sub scheduleConfig {
    my $self = shift;
    $self->render(template => 'scheduleConfig', req => $self->req);
}

#--------------------
#--- SESSION CONT ---
#--------------------

sub sessionAuth {
    return 1 if shift->session('username');
    return undef;
}

sub sessionDeAuth {
    return 1 if shift->session(expires => 1);;
    return undef;
}

sub checkPassword {
    my ($self, $username, $password) = @_;

    return undef unless $username;
    return undef unless $password;

    my $passwdFile = $self->app->config('pwdfile');
    do {
        $self->app->log->error("Cannot read password file '$passwdFile'");
        return undef;
    } unless -r $passwdFile;

    my $result = undef;
    eval {
        my $ht = Apache::Htpasswd->new({ passwdFile => $passwdFile, ReadOnly => 1 });
        $result = $ht->htCheckPassword($username, $password);
    };
    do { $self->app->log->debug("Auth module error: $@"); return undef; } if $@;

    return 1 if $result;

    $self->app->log->info("Bad auth from ".$self->tx->remote_address);
    return undef;
}


sub login {
    my $self = shift;
    return $self->redirect_to('/hello') if $self->sessionAuth;

    my $username = $self->req->param('username') || undef;
    my $password = $self->req->param('password') || undef;

    my $auth =  $self->checkPassword($username, $password);
    if ($auth) {
        $self->session(username => $username);
        return $self->redirect_to('/hello');
    }

    $self->render(template => 'login', req => $self->req);
}

sub logout {
    my $self = shift;
    $self->sessionDeAuth;
    $self->render(template => 'login', req => $self->req);
}
#----------------
#--- CONT END ---
#----------------
1;

#-----------
#--- APP ---
#-----------
package PGmaster;

use utf8;
use strict;
use warnings;
use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;

}

1;
#------------
#--- MAIN ---
#------------
use strict;
use warnings;
use utf8;

use POSIX qw(setuid setgid tzset tzname strftime);
use Mojo::Server::Prefork;
use Mojo::IOLoop::Subprocess;
use Mojo::Util qw(monkey_patch b64_encode b64_decode md5_sum getopt dumper);
use File::Basename;
use Sys::Hostname qw(hostname);
use File::Basename qw(basename dirname);
use Apache::Htpasswd;
use Cwd qw(getcwd abs_path);
use Time::Piece;

my $appfile = abs_path(__FILE__);
my $appname = basename($appfile, ".pl");
$0 = $appfile;

getopt
    'h|help' => \my $help,
    '4|ipv4listen=s' => \my $ipv4listen,
    '6|ipv6listen=s' => \my $ipv6listen,
    'c|config=s' => \my $conffile,
    'p|pwdfile=s' => \my $pwdfile,
    'd|tmpdir=s' => \my $tmpdir,
    'l|logfile=s' => \my $logfile,
    'i|pidfile=s' => \my $pidfile,
    'v|loglevel=s' => \my $loglevel,
    'f|nofork' => \my $nofork,
    'u|user=s' => \my $user,
    'g|group=s' => \my $group;

if ($help) {
    print qq(
Usage: app [OPTIONS]

Options
    -h | --help                      This help
    -4 | --ipv4listen=address:port      Listen address and port, defaults 127.0.0.1:5100
    -6 | --ipv6listen=[address]:port    Listen address and port, defaults [::1]:5100

    -c | --config=path    Path to config file
    -p | --pwdfile=path   Path to user password file
    -d | --tmpdir=path    Path to application files
    -l | --logfile=path   Path to log file
    -i | --pidfile=path   Path to process ID file
    -v | --loglevel=level  Verbose level: debug, info, warn, error, fatal
    -u | --user=user      System owner of process
    -g | --group=group    System group
    -f | --nofork         Dont fork process, for debugging
All path option override option from configuration file

    )."\n";
    exit 0;
}

my $server = Mojo::Server::Prefork->new;
my $app = $server->build_app('PGmaster');
$app = $app->controller_class('PGmaster::Controller');

$app->config(
    hostname => hostname,
    tmpdir => $tmpdir || "/tmp",
    listenIPv4 => $ipv4listen || "0.0.0.0",
    listenIPv6 => $ipv6listen || "[::]",
    listenPort => "3003",

    dbhost => "127.0.0.1",
    dbuser => "postgres",
    dbpasswd => "password",
    dbname => "pgdumper",

    pwdfile => $pwdfile || "@APP_CONFDIR@/$appname.pw",
    pidfile => $pidfile || "@APP_RUNDIR@/$appname.pid",
    logfile => $logfile || "@APP_LOGDIR@/$appname.log",
    conffile => $conffile || "@APP_CONFDIR@/$appname.conf",
    maxrequestsize => 1024*1024*1024,
    tlscert => "@APP_CONFDIR@/$appname.crt",
    tlskey => "@APP_CONFDIR@/$appname.key",
    appuser => $user || "@APP_USER@",
    appgroup => $group || "@APP_GROUP@",
    mode => 'production',
    loglevel => $loglevel || 'info',
    libdir => '@APP_LIBDIR@',
    timezone => 'Europe/Moscow',
);

$conffile = $app->config('conffile');
do {
    $app->log->debug("Load configuration from $conffile ");
    my $config = $app->plugin( 'JSONConfig', { file => $conffile } );
} if -r $conffile;

$ENV{TZ} = $app->config('timezone');;
tzset;

my $tlscert = $app->config('tlscert');
my $tlskey = $app->config('tlskey');
$tmpdir = $app->config('tmpdir');
my $rundir = dirname ($app->config('pidfile'));
my $logdir = dirname ($app->config('logfile'));
$pwdfile = $app->config('pwdfile');

do { print "Error: Cannot write to tmp direcory $tmpdir\n"; exit 1; } unless -w $tmpdir;
do { print "Error: Cannot write to run direcory $rundir\n"; exit 1; } unless -w $rundir;
do { print "Error: Cannot write to log direcory $logdir\n"; exit 1; } unless -w $logdir;

do { print "Error: Cannot read TLS certificate $tlscert\n"; exit 1; } unless -r $tlscert;
do { print "Error: Cannot read TLS key $tlskey\n"; exit 1; } unless -r $tlskey;
do { print "Error: Cannot read password file $pwdfile\n"; exit 1; } unless -r $pwdfile;

my $appUser = $app->config('appuser');
my $appGroup = $app->config('appgroup');

my $appUID = getpwnam($appUser);
my $appGID = getgrnam($appGroup);

do { print "System user $appUser not exist.\n"; exit 1; } unless $appUID;
do { print "System group $appGroup not exist.\n"; exit 1; } unless $appGID;

$app->helper(
    model => sub {
        state $model = PGmaster::Model->new(
            $app,
            $app->config("dbhost"),
            $app->config("dbuser"),
            $app->config("dbpasswd"),
            $app->config("dbname"),
        );
    }
);

$app->moniker($appname);
$app->mode($app->config("mode"));
$app->secrets([ md5_sum('6d578e43ba88260e0375a1a35fd7954b') ]);

$app->hook(before_dispatch => sub {
        my $c = shift;

        my $remoteIPaddr = $c->tx->remote_address;
        my $method = $c->req->method;

        my $base = $c->req->url->base->to_string;
        my $path = $c->req->url->path->to_string;
        my $loglevel = $c->app->log->level;

        my $username  = $c->session('username') || 'undef';

        unless ($loglevel eq 'debug') {
            $c->app->log->info("$method $base$path from $remoteIPaddr as $username");
        }
        if ($loglevel eq 'debug') {
            my $url = $c->req->url->to_abs->to_string;
            $c->app->log->debug("$method $url from $remoteIPaddr as $username");
        }
});

$app->static->paths->[0] = $app->config('libdir').'/public';
$app->renderer->paths->[0] = $app->config('libdir').'/templs';

my $r = $app->routes;

$r->add_condition(
    auth => sub {
        my ($route, $c, $captures, $hash) = @_;
        return 1 if $c->sessionAuth;
        return undef;
    }
);

$r->any('/login')->to('Controller#login');
$r->any('/logout')->to('Controller#logout');
$r->any('/hello')->over('auth')->to('Controller#hello');
# agent forms
$r->any('/agent/list')->over('auth')->to('Controller#agentList');
# agent handlers
$r->any('/agent/add')->over('auth')->to('Controller#agentAdd');
$r->any('/agent/config')->over('auth')->to('Controller#agentConfig');
$r->any('/agent/delete')->over('auth')->to('Controller#agentDelete');
# agent db forms
$r->any('/agent/db/list')->over('auth')->to('Controller#agentDBList');
# agent db handlers
$r->any('/agent/db/create')->over('auth')->to('Controller#agentDBCreate');
$r->any('/agent/db/drop')->over('auth')->to('Controller#agentDBDrop');
$r->any('/agent/db/copy')->over('auth')->to('Controller#agentDBCopy');
$r->any('/agent/db/rename')->over('auth')->to('Controller#agentDBRename');
$r->any('/agent/db/dump')->over('auth')->to('Controller#agentDBDump');
$r->any('/agent/db/restore')->over('auth')->to('Controller#agentDBRestore');

# store forms
$r->any('/store/list')->over('auth')->to('Controller#storeList');
# store handlers
$r->any('/store/add')->over('auth')->to('Controller#storeAdd');
$r->any('/store/config')->over('auth')->to('Controller#storeConfig');
$r->any('/store/delete')->over('auth')->to('Controller#storeDelete');
# store data manipulation
$r->any('/store/data/list')->over('auth')->to('Controller#storeDataList');
$r->any('/store/data/delete')->over('auth')->to('Controller#storeDataDelete');
$r->any('/store/data/download')->over('auth')->to('Controller#storeDataDownload');

# generic data list
$r->any('/data/list')->over('auth')->to('Controller#dataList');
# generic job list
$r->any('/job/list')->over('auth')->to('Controller#jobList');


$r->any('/schedule/list')->over('auth')->to('Controller#scheduleList');
$r->any('/schedule/add')->over('auth')->to('Controller#scheduleAdd');
$r->any('/schedule/delete')->over('auth')->to('Controller#scheduleDelete');
$r->any('/schedule/config')->over('auth')->to('Controller#scheduleConfig');

# callback handlers
$r->any('/agent/job/cb')->to('Controller#jobCB');
$r->any('/store/job/cb')->to('Controller#jobCB');


#$app->helper('reply.exception' => sub { my $c = shift; return $c->rendered(404); });
$app->helper('reply.not_found' => sub {
        my $c = shift;
        return $c->redirect_to('/login') unless $c->sessionAuth;
        $c->render(template => 'not_found.production');
});

my $tlsParam .= '?';
$tlsParam .= 'cert='.$tlscert;
$tlsParam .= '&key='.$tlskey;

my $listenPort = $app->config('listenPort');
my $listenIPv4 = $app->config('listenIPv4');
my $listenIPv6 = $app->config('listenIPv6');

$server->listen([
    "https://$listenIPv4:$listenPort$tlsParam",
]);

$server->pid_file($app->config('pidfile'));

$server->heartbeat_interval(3);
$server->heartbeat_timeout(60);

#my $id3 = $server->ioloop->recurring(3 => sub {
#            my $loop = shift;
#            open my $handle, '<', $server->pid_file;
#            my $pid = <$handle>;
#            chomp $pid;
##            return 1 unless $$ == $pid;
#            print "   Hi 3! $pid $$\n";
#});

my $subprocess = Mojo::IOLoop::Subprocess->new;
$app->log->info("----");

my $log = $app->log;

$app->config(last => 0);

sub cron {
    my $loop = shift;
    my $m = $app->model;

    my $last = time;
    my $stamp = $m->timestamp($last);

    my $currSec = $m->currSec;
    $app->config(lastCron => $last);

    my $scheduleList = $m->scheduleList;
    my $currTime = $m->currTime;

    $log->debug("Achtung: $stamp !");
    foreach my $rec (@{$scheduleList}) {
        my $id = $rec->{'id'};
        my $currSec = $currTime->{'sec'};
        my $currMin = $currTime->{'min'};

        my $recMin = $rec->{'min'};
        my $recHour = $rec->{'hour'};

        $log->debug("--- Match id=$id $recMin == $currMin!") if $m->periodMatch($currMin, $m->periodExpand($recMin, 59, 0));
#        $log->debug("Unmatch id=$id!") unless $m->periodMatch($currTime->{'min'}, $m->periodExpand($recMin));

#  "hour" => "6,23",
#  "id" => 2,
#  "mday" => "1-31",
#  "min" => 16,
#  "sourceid" => 1,
#  "subject" => "asterisk_copy",
#  "type" => "dump",
#  "wday" => "1-7"


    }
    $log->debug("");
    sleep 60-$currSec;
}

$subprocess->run(
    sub {
        my $subproc = shift;
        my $loop = Mojo::IOLoop->singleton;
        my $id = $loop->recurring(1 => \&cron );
        $loop->start unless $loop->is_running;
    },
    sub {
        my ($subprocess, $err, @results) = @_;
        $app->log->info('Exit subprocess');
        return 1;
    }
);

unless ($nofork) {
    my $pid = fork;
    if ($pid == 0) {
        setuid($appUID) if $appUID;
        setgid($appGID) if $appGID;
        $app->log(Mojo::Log->new( path => $app->config('logfile') ));
        open (my $STDOUT2, '>&', STDOUT); open (STDOUT, '>>', '/dev/null');
        open (my $STDERR2, '>&', STDERR); open (STDERR, '>>', '/dev/null');
        chdir($tmpdir);
        local $SIG{HUP} = sub {
                $app->log(Mojo::Log->new(
                        path => $app->config('logfile'),
                        level => $app->config('loglevel'),
                ));
        };


        $server->run;
    }
} else {
    setuid($appUID) if $appUID;
    setgid($appGID) if $appGID;
    $server->run;
}
#EOF
