#!@PERL@

#--------------
#--- DAEMON ---
#--------------

package PGmaster::Daemon;

use strict;
use warnings;
use POSIX qw(getpid setuid setgid geteuid getegid);
use Cwd qw(cwd getcwd chdir);
use Mojo::Util qw(dumper);

sub new {
    my $class = shift;
    my $self = {
        pid => undef
    };
    bless $self, $class;
    return $self;
}

sub fork {
    my ($self, $user, $group) = shift;
    my $pid = fork;
    if ($pid > 0) {
        exit;
    }
    chdir("/");
    open(my $stdout, '>&', STDOUT); 
    open(my $stderr, '>&', STDERR);
    open(STDOUT, '>>', '/dev/null');
    open(STDERR, '>>', '/dev/null');
    $self->pid(getpid);
    $self->pid;
}

sub pid {
    my ($self, $pid) = @_;
    return $self->{pid} unless $pid;
    $self->{pid} = $pid if $pid;
    $self;
}

1;

#----------
#--- DB ---
#----------

package PGmaster::DB;

use strict;
use warnings;
use DBI;

sub new {
    my ($class, %args) = @_;
    my $self = {
        hostname => $args{hostname},
        username => $args{username},
        password => $args{password},
        database => $args{database},
        engine => 'Pg',
        error => ''
    };
    bless $self, $class;
    return $self;
}

sub username {
    my ($self, $username) = @_; 
    return $self->{username} unless $username;
    $self->{username} = $username;
    $self;
}

sub password {
    my ($self, $password) = @_; 
    return $self->{password} unless $password;
    $self->{password} = $password;
    $self;
}

sub hostname {
    my ($self, $hostname) = @_; 
    return $self->{hostname} unless $hostname;
    $self->{hostname} = $hostname;
    $self;
}

sub database {
    my ($self, $database) = @_; 
    return $self->{database} unless $database;
    $self->{database} = $database;
    $self;
}

sub error {
    my ($self, $error) = @_; 
    return $self->{error} unless $error;
    $self->{error} = $error;
    $self;
}

sub engine {
    my ($self, $engine) = @_; 
    return $self->{engine} unless $engine;
    $self->{engine} = $engine;
    $self;
}


sub exec {
    my ($self, $query) = @_;
    return undef unless $query;

    my $dsn = 'dbi:'.$self->engine.
                ':dbname='.$self->database.
                ';host='.$self->hostname;
    my $dbi;
    eval {
        $dbi = DBI->connect($dsn, $self->username, $self->password, { 
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1 
        });
    };
    $self->error($@);
    return undef if $@;

    my $sth;
    eval {
        $sth = $dbi->prepare($query);
    };
    $self->error($@);
    return undef if $@;

    my $rows = $sth->execute;
    my @list;

    while (my $row = $sth->fetchrow_hashref) {
        push @list, $row;
    }
    $sth->finish;
    $dbi->disconnect;
    \@list;
}

sub do {
    my ($self, $query) = @_;
    return undef unless $query;
    my $dsn = 'dbi:'.$self->engine.
                ':dbname='.$self->database.
                ';host='.$self->hostname;
    my $dbi;
    eval {
        $dbi = DBI->connect($dsn, $self->username, $self->password, { 
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1 
        });
    };
    $self->error($@);
    return undef if $@;
    my $rows;
    eval {
        $rows = $dbi->do($query) or return undef;
    };
    $self->error($@);
    return undef if $@;

    $dbi->disconnect;
    $rows*1;
}

1;

#-------------
#--- MODEL ---
#-------------

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
    my ($class, $app, $db) = @_;
    my $self = {
        app => $app,
        db => $db
    };
    bless $self, $class;
    return $self;
}

sub db {
    return shift->{db};
}

sub app {
    return shift->{app};
}

sub hostname_alive {
    my ($self, $hostname) = @_;
    return undef unless gethostbyname($hostname);
    return 1;
}

sub parse_label {
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

sub curr_sec {
    my $self = shift;
    return strftime("%S", localtime(time));
}

sub curr_time {
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

sub size_hr {
    my ($self, $size) = @_;
    return $size if $size < 1024;
    return int($size/1024+0.5)."k" if ($size < 1024*1024 && $size > 1024);
    return int($size/(1024*1024)+0.5)."M" if ($size < 1024*1024*1024 && $size > 1024*1024);
    return int($size/(1024*1024*1024)+0.5)."G" if ($size < 1024*1024*1024*1024 && $size > 1024*1024*1024);
}

sub size_wp {
    my ($self, $size) = @_;
    my $out = $size;
    $out =~ s/(\d{9})$/.$1/g if $size > 1000*1000*1000;
    $out =~ s/(\d{6})$/.$1/g if $size > 1000*1000;
    $out =~ s/(\d{3})$/.$1/g if $size > 1000;
    return $out;
}

sub size_m {
    my ($self, $size) = @_;
    return int($size/(1024*1024)+0.5);
}

sub strip_sec {
    my ($self, $s) = @_;
    my $a = substr $s, 0, 16;
    $a =~ s/\//-/g;
    return $a;
}

#-------------------
#--- AGENT MODEL ---
#-------------------

sub agent_list {
    my ($self, $id)  = @_;
    my $where = '';
    $where = "where id = $id" if $id;
    my $query = "select * from agent $where order by hostname;";
    $self->db->exec($query);
}

sub agent_exist {
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

sub agent_hostname {
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

sub agent_profile {
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

sub agent_info {
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

sub agent_next_id {
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

sub agent_add {
    my ($self, $hostname, $username, $password) = @_;
    return undef unless $hostname;
    return undef unless $username;
    return undef unless $password;

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
         or return undef;
    my $id = $self->agent_next_id;
    my $query = "insert into agent (id, hostname, username, password)
                    values ($id, '$hostname', '$username', '$password');";
    my $rows = $dbi->do($query) or return undef;
    $dbi->disconnect;

    return $id if $rows*1 > 0;
    return undef;
}

sub agent_delete {
    my ($self, $id) = @_;
    return undef unless $id;

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "delete from agent where id = $id;";
    my $rows = $dbi->do($query) or return undef;

    $dbi->disconnect;
    return $rows*1;
}

sub agent_config {
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

sub agent_alive {
    my ($self, $id) = @_;
    return undef unless $id;
    my $hostname = $self->agent_hostname($id);
    return undef unless $hostname;
    my $ua = Mojo::UserAgent->new;
    $ua = $ua->connect_timeout(5);


    my $tx = $ua->get("https://$hostname:3001/hello");
    my $body;
    eval {
        $body = $tx->result->body;
    };
    do { $self->app->log->info("agent_alive: $@");  return undef; } if $@;
    return undef unless $body;
    my $res = decode_json $body;
    return 1 if $res->{'message'} eq 'hello';
    return undef;
}

sub agent_db_list {
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

sub agent_db_update {
    my ($self, $id) = @_;
    return undef unless $id;
    my $agent_profile = $self->agentProfile($id) or return undef;

    my $hostname = $agent_profile->{'hostname'} || 'undef';
    my $username = $agent_profile->{'username'} || 'undef';
    my $password = $agent_profile->{'password'} || 'password';

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

sub store_hostname {
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

sub store_profile {
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

sub store_info {
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

sub store_alive {
    my ($self, $id) = @_;
    return undef unless $id;
    my $hostname = $self->store_hostname($id);
    return undef unless $hostname;

    my $ua = Mojo::UserAgent->new;
    $ua = $ua->connect_timeout(5);
    my $tx = $ua->get("https://$hostname:3002/hello");

    my $body;
    eval { $body = $tx->result->body; };
    do { $self->app->log->info("store_alive: $@"); return undef; } if $@;
    return undef unless $body;

    my $res = decode_json $body;

    return 1 if $res->{'message'} eq 'hello';
    return undef;
}

sub store_list {
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

sub store_exist {
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

sub store_next_id {
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

sub store_add {
    my ($self, $hostname, $username, $password) = @_;
    return undef unless $hostname;
    return undef unless $username;
    return undef unless $password;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $id = $self->store_next_id;
    my $query = "insert into store (id, hostname, username, password)
                    values ($id, '$hostname', '$username', '$password');";
    my $rows = $dbi->do($query) or return undef;
    $dbi->disconnect;
    return $id if $rows*1 > 0;
    return undef;
}

sub store_delete {
    my ($self, $id) = @_;

    return undef unless $id;

    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;
    my $query = "delete from store where id = $id;";
    my $rows = $dbi->do($query) or return undef;

    $dbi->disconnect;
    return $rows*1;
}

sub store_config {
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

sub store_data_list {
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

sub store_data_update {
    my ($self, $id) = @_;
    return undef unless $id;
    my $store_profile = $self->store_profile($id) or return undef;

    my $hostname = $store_profile->{'hostname'} || 'undef';
    my $username = $store_profile->{'username'} || 'undef';
    my $password = $store_profile->{'password'} || 'password';

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
        my $label = $self->app->model->parse_label($dataname);
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

sub store_free {
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

sub data_list {
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

sub job_create {
    my ($self, @args) = @_;

    my $id = $self->job_nextID;

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

sub job_list {
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

sub job_nextID {
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

sub job_exist {
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

sub job_update {
    my ($self, $id, %args) = @_;

    return undef unless $id;
    return undef unless $self->job_exist($id);

    my $job_profile = $self->job_profile($id);
    my $args = \%args;

    my $begin = $args->{'begin'} || $job_profile->{'begin'};
    my $stop = $args->{'stop'} || $job_profile->{'stop'};
    my $type = $args->{'type'} || $job_profile->{'type'};
    my $author = $args->{'author'} || $job_profile->{'author'};
    my $sourceid = $args->{'sourceid'} || $job_profile->{'sourceid'};
    my $destid = $args->{'destid'} || $job_profile->{'destid'};

    my $status = $args->{'status'} || $job_profile->{'status'};
    my $error = $args->{'error'} || $job_profile->{'error'};
    my $message = $args->{'message'} || $job_profile->{'message'};

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

sub job_delete {
    my ($self, $id) = @_;
    my $dbi = DBI->connect($self->dsn, $self->dbuser, $self->dbpasswd)
        or return undef;

    my $query = "delete from job where id = $id;";
    my $rows = $dbi->do($query) or return undef;

    $dbi->disconnect;

    return $rows if $rows;
    return undef;
}

sub job_profile {
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

sub job_cb {
    my ($self, $req)  = @_;

    my $jobID = $req->param('jobid');
    my $magic = $req->param('magic');

    return undef unless $jobID;
    return undef unless $magic;

    my $job_profile = $self->job_profile($jobID);

    my $error = $req->param('error');
    my $status = $req->param('status');
    my $message = $req->param('message');

    $self->job_update($jobID, error => $error, stop => $self->timestamp) if $error;
    $self->job_update($jobID, status => $status, stop => $self->timestamp) if $status;
    $self->job_update($jobID, message => $message, stop => $self->timestamp) if $message;

    return 1;
}
#----------------------
#--- SCHEDULE MODEL ---
#----------------------

sub schedule_list {
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

sub schedule_profile {
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

sub schedule_next_id {
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

sub schedule_add {
    my ($self, $type, $sourceID, $destID, $subject, $mday, $wday, $hour, $min) = @_;

    $self->app->log->debug("--- schedule_add: $type, $sourceID, $destID, $subject, $mday, $wday, $hour, $min");

    return undef unless $type;
    return undef unless $sourceID;
    return undef unless $destID;
    return undef unless $subject;
    return undef unless $mday;
    return undef unless $wday;
    return undef unless $hour;
    return undef unless $min;

    my $id = $self->schedule_next_id;
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


sub period_expand {
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

sub period_compact {
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

sub period_match {
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

sub agent_list {
    my $self = shift;
    $self->render(template => 'agent_list');
}

sub agent_add {
    my $self = shift;
    $self->render(template => 'agent_add', req => $self->req);
}

sub agent_config {
    my $self = shift;
    $self->render(template => 'agent_config', req => $self->req);
}

sub agent_delete {
    my $self = shift;
    $self->render(template => 'agent_delete', req => $self->req);
}

sub agent_db_list {
    my $self = shift;
    my $id = $self->req->param('id');
    $self->render(template => 'agent_db_list', req => $self->req);
}

sub agent_db_create {
    my $self = shift;
    $self->render(template => 'agent_db_create', req => $self->req);
}

sub agent_db_drop {
    my $self = shift;
    $self->render(template => 'agent_db_drop', req => $self->req);
}

sub agent_db_rename {
    my $self = shift;
    $self->render(template => 'agent_db_rename', req => $self->req);
}

sub agent_db_copy {
    my $self = shift;
    $self->render(template => 'agent_db_copy', req => $self->req);
}

sub agent_db_dump {
    my $self = shift;
    $self->render(template => 'agent_db_dump', req => $self->req);
}

sub agent_db_restore {
    my $self = shift;
    $self->render(template => 'agent_db_restore', req => $self->req);
}

#------------------
#--- STORE CONT ---
#------------------

sub store_list {
    my $self = shift;
    $self->render(template => 'store_list');
}

sub store_add {
    my $self = shift;
    $self->render(template => 'store_add', req => $self->req);
}

sub store_config {
    my $self = shift;
    $self->render(template => 'store_config', req => $self->req);
}

sub store_delete {
    my $self = shift;
    $self->render(template => 'store_delete', req => $self->req);
}

sub store_data_list {
    my $self = shift;
    $self->render(template => 'store_data_list', req => $self->req);
}

sub store_data_delete {
    my $self = shift;
    $self->render(template => 'store_data_delete', req => $self->req);
}

sub store_data_download {
    my $self = shift;
    $self->render(template => 'store_data_download', req => $self->req);
}


#-------------
#--- XXXXX ---
#-------------

sub data_list {
    my $self = shift;
    $self->render(template => 'data_list', req => $self->req);
}

#----------------
#--- JOB CONT ---
#----------------

sub job_list {
    my $self = shift;
    $self->render(template => 'job_list', req => $self->req);
}

sub job_cb {
    my $self = shift;
    $self->app->model->job_cb($self->req);
    $self->render(json => { responce => 'success' } );
}

#---------------------
#--- SCHEDULE CONT ---
#---------------------

sub schedule_list {
    my $self = shift;
    $self->render(template => 'schedule_list', req => $self->req);
}

sub schedule_add {
    my $self = shift;
    $self->render(template => 'schedule_add', req => $self->req);
}

sub schedule_delete {
    my $self = shift;
    $self->render(template => 'schedule_delete', req => $self->req);
}

sub schedule_config {
    my $self = shift;
    $self->render(template => 'schedule_config', req => $self->req);
}

#--------------------
#--- SESSION CONT ---
#--------------------

sub pwfile {
    my ($self, $pwdfile) = @_;
    return $self->app->config('pwdfile') unless $pwdfile;
    $self->app->config(pwfile => $pwdfile);
}

sub ucheck {
    my ($self, $username, $password) = @_;
    return undef unless $password;
    return undef unless $username;
    my $pwdfile = $self->pwfile or return undef;
    my $res = undef;
    eval {
        my $ht = Apache::Htpasswd->new({ passwdFile => $pwdfile, ReadOnly => 1 });
        $res = $ht->htCheckPassword($username, $password);
    };
    $res;
}

sub login {
    my $self = shift;
    return $self->redirect_to('/') if $self->session('username');

    my $username = $self->req->param('username') || undef;
    my $password = $self->req->param('password') || undef;

    return $self->render(template => 'login') unless $username and $password;

    if ($self->ucheck($username, $password)) {
        $self->session(username => $username);
        return $self->redirect_to('/');
    }
    $self->render(template => 'login');
}

sub logout {
    my $self = shift;
    $self->session(expires => 1);
    $self->redirect_to('/');
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

my $appname = 'pgmaster';

#--------------
#--- GETOPT ---
#--------------

getopt
    'h|help' => \my $help,
    'c|config=s' => \my $conffile,
    'f|nofork' => \my $nofork,
    'u|user=s' => \my $user,
    'g|group=s' => \my $group;


if ($help) {
    print qq(
Usage: app [OPTIONS]

Options
    -h | --help           This help
    -c | --config=path    Path to config file
    -u | --user=user      System owner of process
    -g | --group=group    System group 
    -f | --nofork         Dont fork process

The options override options from configuration file
    )."\n";
    exit 0;
}

#------------------
#--- APP CONFIG ---
#------------------

my $server = Mojo::Server::Prefork->new;
my $app = $server->build_app('PGmaster');
$app = $app->controller_class('PGmaster::Controller');

$app->secrets(['6d578e43ba88260e0375a1a35fd7954b']);
$app->static->paths(['@APP_LIBDIR@/public']);
$app->renderer->paths(['@APP_LIBDIR@/templs']);

$app->config(conffile => $conffile || '@APP_CONFDIR@/pgmaster.conf');
$app->config(pwdfile => '@APP_CONFDIR@/pgmaster.pw');
$app->config(logfile => '@APP_LOGDIR@/pgmaster.log');
$app->config(loglevel => 'info');
$app->config(pidfile => '@APP_RUNDIR@/pgmaster.pid');
$app->config(crtfile => '@APP_CONFDIR@/pgmaster.crt');
$app->config(keyfile => '@APP_CONFDIR@/pgmaster.key');

$app->config(user => $user || '@APP_USER@');
$app->config(group => $group || '@APP_GROUP@');

$app->config(listenaddr4 => '0.0.0.0');
$app->config(listenaddr6 => '[::]');
$app->config(listenport => '3003');

$app->config(tmpdir => '/tmp');

$app->config(dbhost => '127.0.0.1');
$app->config(dbuser => 'postgres');
$app->config(dbpwd => 'password');
$app->config(dbname => 'pgdumper');

if (-r $app->config('conffile')) {
    $app->log->debug("Load configuration from ".$app->config('conffile'));
    $app->plugin('JSONConfig', { file => $app->config('conffile') });
}

#---------------
#--- HELPERS ---
#---------------

$app->helper('reply.not_found' => sub {
        my $c = shift; 
        return $c->redirect_to('/login') unless $c->session('username'); 
        $c->render(template => 'not_found.production');
});

$app->helper(
    model => sub {
        my $db = PGmaster::DB->new(
                        hostname => $app->config("dbhost"),
                        username => $app->config("dbuser"),
                        password => $app->config("dbpwd"),
                        database => $app->config("dbname"),
        );
        state $model = PGmaster::Model->new($app, $db);
    }
);

#--------------
#--- ROUTES ---
#--------------

my $r = $app->routes;

$r->add_condition(
    auth => sub {
        my ($route, $c) = @_;
        $c->session('username');
    }
);

$r->any('/login')->to('controller#login');
$r->any('/logout')->to('controller#logout');
$r->any('/hello')->over('auth')->to('controller#hello');
# agent forms
$r->any('/agent/list')->over('auth')->to('controller#agentList');
# agent handlers
$r->any('/agent/add')->over('auth')->to('controller#agentAdd');
$r->any('/agent/config')->over('auth')->to('controller#agentConfig');
$r->any('/agent/delete')->over('auth')->to('controller#agentDelete');
# agent db forms
$r->any('/agent/db/list')->over('auth')->to('controller#agentDBList');
# agent db handlers
$r->any('/agent/db/create')->over('auth')->to('controller#agentDBCreate');
$r->any('/agent/db/drop')->over('auth')->to('controller#agentDBDrop');
$r->any('/agent/db/copy')->over('auth')->to('controller#agentDBCopy');
$r->any('/agent/db/rename')->over('auth')->to('controller#agentDBRename');
$r->any('/agent/db/dump')->over('auth')->to('controller#agentDBDump');
$r->any('/agent/db/restore')->over('auth')->to('controller#agentDBRestore');

# store forms
$r->any('/store/list')->over('auth')->to('controller#storeList');
# store handlers
$r->any('/store/add')->over('auth')->to('controller#storeAdd');
$r->any('/store/config')->over('auth')->to('controller#storeConfig');
$r->any('/store/delete')->over('auth')->to('controller#storeDelete');
# store data manipulation
$r->any('/store/data/list')->over('auth')->to('controller#storeDataList');
$r->any('/store/data/delete')->over('auth')->to('controller#storeDataDelete');
$r->any('/store/data/download')->over('auth')->to('controller#storeDataDownload');

# generic data list
$r->any('/data/list')->over('auth')->to('controller#dataList');
# generic job list
$r->any('/job/list')->over('auth')->to('controller#jobList');


$r->any('/schedule/list')->over('auth')->to('controller#scheduleList');
$r->any('/schedule/add')->over('auth')->to('controller#scheduleAdd');
$r->any('/schedule/delete')->over('auth')->to('controller#scheduleDelete');
$r->any('/schedule/config')->over('auth')->to('controller#scheduleConfig');

# callback handlers
$r->any('/agent/job/cb')->to('controller#jobCB');
$r->any('/store/job/cb')->to('controller#jobCB');

#----------------
#--- LISTENER ---
#----------------

my $tls = '?';
$tls .= 'cert='.$app->config('crtfile');
$tls .= '&key='.$app->config('keyfile');

my $listen4;
if ($app->config('listenaddr4')) {
    $listen4 = "https://";
    $listen4 .= $app->config('listenaddr4').':'.$app->config('listenport');
    $listen4 .= $tls;
}

my $listen6;
if ($app->config('listenaddr6')) {
    $listen6 = "https://";
    $listen6 .= $app->config('listenaddr6').':'.$app->config('listenport');
    $listen6 .= $tls;
}

my @listen;
push @listen, $listen4 if $listen4;
push @listen, $listen6 if $listen6;

$server->listen(\@listen);
$server->heartbeat_interval(3);
$server->heartbeat_timeout(60);

#--------------
#--- DAEMON ---
#--------------

unless ($nofork) {
    my $d = PGmaster::Daemon->new;
    my $user = $app->config('user');
    my $group = $app->config('group');
    $d->fork;
    $app->log(Mojo::Log->new( 
                path => $app->config('logfile'),
                level => $app->config('loglevel')
    ));
}

$server->pid_file($app->config('pidfile'));

#---------------
#--- WEB LOG ---
#---------------

$app->hook(before_dispatch => sub {
        my $c = shift;

        my $remote_address = $c->tx->remote_address;
        my $method = $c->req->method;

        my $base = $c->req->url->base->to_string;
        my $path = $c->req->url->path->to_string;
        my $loglevel = $c->app->log->level;
        my $url = $c->req->url->to_abs->to_string;

        unless ($loglevel eq 'debug') {
            #$c->app->log->info("$remote_address $method $base$path");
            $c->app->log->info("$remote_address $method $url");
        }
        if ($loglevel eq 'debug') {
            $c->app->log->debug("$remote_address $method $url");
        }
});

#----------------------
#--- SIGNAL HANDLER ---
#----------------------

local $SIG{HUP} = sub {
    $app->log->info('Catch HUP signal'); 
    $app->log(Mojo::Log->new(
                    path => $app->config('logfile'),
                    level => $app->config('loglevel')
    ));
};

$server->run;


#EOF
