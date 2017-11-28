#!@PERL@

#------------
#--- AUTH ---
#------------

package PGagent::BasicAuth;

use strict;
use warnings;
use POSIX qw(getpid setuid setgid geteuid getegid);
use Cwd qw(cwd getcwd chdir);
use Mojo::Util qw(md5_sum b64_decode dumper);
use Apache::Htpasswd;

sub new {
    my ($class, $pwdfile) = @_;
    my $self = {
        pwdfile => $pwdfile,
        errstr => undef
    };
    bless $self, $class;
    return $self;
}

sub pwdfile {
    my ($self, $pwdfile) = @_;
    return $self->{pwdfile} unless $pwdfile;
    $self->{pwdfile} = $pwdfile if $pwdfile;
    $self;
}

sub auth {
    my ($self, $authstr) = @_;
    return undef unless $authstr;

    my $hash = $self->split($authstr);
    return undef unless $hash;
    return undef unless -r $self->{pwdfile};

    my $res = undef;
    eval {
        my $ht = Apache::Htpasswd->new( { passwdFile => $self->pwdfile, ReadOnly => 1 } );
        $res = $ht->htCheckPassword(
                            $hash->{username},
                            $hash->{password}
        );
    };
    return undef if $@;
    $res;
}

sub username {
    my ($self, $authstr) = @_;
    return undef unless $authstr;
    my $hash = $self->split($authstr);
    return undef unless $hash;
    $hash->{username} if $hash;
}

sub split {
    my ($self, $authstr) = @_;
    return undef unless $authstr;

    my ($type, $enc) = split /\s+/, $authstr;
    return undef unless ($type eq 'Basic' && $enc);

    my ($username, $password) = split /:/, b64_decode($enc);
    return undef unless ($username && $password);

    { username => $username, password => $password };
}

1;


#--------------
#--- DAEMON ---
#--------------

package PGagent::Daemon;

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

package PGagent::DB;

use strict;
use warnings;
use DBI;

sub new {
    my ($class, %args) = @_;
    my $self = {
        hostname => $args{hostname} || 'localhost',
        username => $args{username} || 'postgres',
        password => $args{password} || 'password',
        database => $args{database} || 'postgres',
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

package PGagent::Model;

use strict;
use warnings;
use File::stat;
use Data::Dumper;
use DBI;
use Mojo::UserAgent;
use Mojo::Util qw(dumper);
use Mojo::JSON qw(encode_json decode_json true false);
use POSIX;
use Socket;

#sub new {
#    my ($class, $app, $dbhost, $dbuser, $dbpwd) = @_;
#    my $self = {
#        app => $app,
#        db => PGagent::DB->new(
#                        hostname => $dbhost,
#                        username => $dbuser,
#                        password => $dbpwd,
#                        database => 'postgres',
#        )
#    };
#    bless $self, $class;
#    return $self;
#}

sub new {
    my ($class, $app, $db) = @_;
    my $self = {
        app => $app,
        db => $db
    };
    bless $self, $class;
    return $self;
}

sub app {
    shift->{app}; 
}

sub db {
    shift->{db}; 
}

sub log {
    shift->app->log; 
}

sub hello {
    "hello!";
}

sub store_alive {
    my ($self, $hostname) = @_;
    return undef unless $hostname;

    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->get("https://$hostname:3002/hello");
    $ua = $ua->connect_timeout(5)->request_timeout(5);;

    my $res;
    eval { $res = decode_json($tx->result->body); };
    return 1 if $res->{'message'} eq 'hello';
    return undef;
}

sub store_put {
    my ($self, $datafile, $storename, $storeuser, $storepwd) = @_;
    my $ua = Mojo::UserAgent->new(max_redirects => 5);
    $ua = $ua->connect_timeout(15)->request_timeout(15);;

    return undef unless $datafile;
    return undef unless $storename;

    return undef unless -f $datafile;
    return undef unless -r $datafile;
    return undef unless $self->store_alive($storename);

    $self->app->log->info("store_put: Start upload $datafile to store $storename");
    my $tx = $ua->post("https://$storeuser:$storepwd\@$storename:3002/data/put" =>
                            form => { data => { file => $datafile }} );
    $self->app->log->info("store_put: End upload $datafile to store $storename");

    my $res;
    eval { $res = $tx->result; };
    return $res->body if $res;
    return undef;
}

sub store_get {
    my ($self, $dataset, $storename, $storeuser, $storepwd) = @_;
    return undef unless $dataset;
    return undef unless $storename;
    return undef unless $self->store_alive($storename);

    $storeuser = 'undef' unless $storeuser;
    $storepwd = 'undef' unless $storepwd;

    my $tmpdir = $self->app->config('tmpdir');

    return undef unless -d $tmpdir;
    return undef unless -w $tmpdir;

    my $datafile = "$tmpdir/rest".."$dataset";
    $self->app->log->info("store_get: Start download $dataset from store $storename to $datafile");

    my $ua = Mojo::UserAgent->new(max_redirects => 5);
    $ua = $ua->connect_timeout(30)->request_timeout(30);;

    my $tx = $ua->get("https://$storeuser:$storepwd\@$storename:3002/data/get?dataname=$dataset");
    $tx->result->content->asset->move_to($datafile);
    $self->app->log->info("store_get: End download $dataset from store $storename");

    return $datafile if -r $datafile;
    unlink $datafile; return undef;
}


#-----------------
#--- DB MODEL ----
#-----------------

sub db_exist {
    my ($self, $dbname) = @_;
    return undef unless $dbname;
    my $dblist = $self->db_list;
    foreach my $db (@$dblist) {
        return 1 if $db->{"name"} eq $dbname;
    }
    return undef;
}

sub db_size {
    my ($self, $dbname) = @_;
    return undef unless $dbname;
    return undef unless $self->db_exist($dbname);

    my $query = "select pg_database_size('$dbname') as size;";
    my $res = $self->db->exec($query);
    $res->[0]{size};
}

sub db_list {
    my $self = shift;
    my $query = "select d.datname as name,
                        pg_database_size(d.datname) as size,
                        u.usename as owner,
                        s.numbackends as numbackends
                 from pg_database d, pg_user u, pg_stat_database s
                 where d.datdba = u.usesysid and d.datname = s.datname
                 order by d.datname;";
    $self->db->exec($query);
}

sub db_create {
    my ($self, $dbname) = @_;
    return undef unless $dbname;
    return undef if $self->db_exist($dbname);
    my $query = "create database $dbname";
    $self->db->do($query);
    $self->db_exist($dbname);
}

sub db_drop {
    my ($self, $dbname) = @_;
    return undef unless $dbname;
    return undef unless $self->db_exist($dbname);
    my $query = "drop database $dbname";
    $self->db->do($query);
    return undef if $self->db_exist($dbname);
    $dbname;
}

sub db_rename {
    my ($self, $dbname, $newname) = @_;
    return undef unless $dbname;
    return undef unless $newname;
    return undef unless $self->db_exist($dbname);

    my $query = "alter database $dbname rename to $newname;";
    $self->db->do($query);
    $self->db_exist($newname);
}

sub db_copy {
    my ($self, $dbname, $newname) = @_;
    return undef unless $dbname;
    return undef unless $newname;
    return undef unless $self->db_exist($dbname);
    return undef if $self->db_exist($newname);

    my $query = "create database $newname template $dbname;";
    $self->db->do($query);
    $self->db_exist($newname);
}


sub db_dump {
    my ($self, $dbname, $hostname, $tmpdir) = @_;

    return undef unless $dbname;
    return undef unless $self->db_exist($dbname);

    return undef unless -d $tmpdir;
    return undef unless -w $tmpdir;

    my $timestamp = strftime("%Y%m%d-%H%M%S-%Z", localtime(time));
    my $dbdump = "$tmpdir/$dbname--$timestamp--$hostname.sqlz";

    my $password = $self->password;
    my $pghost = $self->pghost;
    my $username = $self->username;

    my $out = qx/PGPASSWORD=$password pg_dump -h $pghost -U $username -Fc -f $dbdump $dbname 2>&1/;
    my $retcode = $?;

    return $dbdump if $retcode == 0;
    undef;
}

sub db_restore {
    my ($self, $filename, $dbname) = @_;
    return undef unless $dbname;
    return undef unless $filename;
    return undef unless -r $filename;
    return undef unless -s $filename;

    return undef if $self->db_exist($dbname);

    return undef unless $self->db_create($dbname);

    my $password = $self->password;
    my $pghost = $self->pghost;
    my $username = $self->username;

    my $out = qx/PGPASSWORD=$password pg_restore -j 4 -h $pghost -U $username -Fc -d $dbname $filename 2>&1/;
    my $retcode = $?;

    if ($retcode > 1) {
        $self->db_drop($dbname) if $self->db_exist($dbname);
        return undef;
    }
    $dbname;
}

sub db_owner {
    my ($self, $dbname) = @_;
    return undef unless $dbname;
    return undef unless $self->db_exist($dbname);
    my $query = "select u.usename as username, d.datname as dbname 
                        from pg_database d, pg_user u 
                        where d.datdba = u.usesysid and d.datname = '$dbname' limit 1";
    $self->db->exec($query);
}


#-------------------
#--- ROLE MODEL ----
#-------------------


sub role_list {
    my $self = shift;
    my $query = "select usename as rolename from pg_user order by rolename";
    $self->db->exec($query);
}

sub role_exist {
    my ($self, $role) = @_;
    return undef unless $role;
    my $list = $self->role_list;
    foreach my $name (@{$self->role_list}) {
        return $name->{rolename} if $name->{rolename} eq $role;
    }
    return undef;
}

sub role_create {
    my ($self, $rolename, $password) = @_;
    return undef unless $password;
    return undef unless $rolename;
    return undef unless $self->role_exist($rolename);

    my $query = "create user '$rolename' encrypted password '$password';";
    $self->db->do($query);
    $self->role_exist($rolename);
}

sub role_drop {
    my ($self, $rolename) = @_;
    return undef unless $rolename;
    return undef unless $self->role_exist($rolename);

    my $query = "drop user '$rolename';";
    $self->db->do($query);
    return undef if $self->role_exist($rolename);
    $rolename;
}

sub role_password {
    my ($self, $rolename, $password) = @_;
    return undef unless $password;
    return undef unless $rolename;
    return undef unless $self->role_exist($rolename);

    my $query = "alter role $rolename encrypted password '$password'";
    $self->db->do($query);
    $self->role_exist($rolename);
}

1;

#------------------
#--- CONTROLLER ---
#------------------

package PGagent::Controller;

use utf8;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(dumper);
use Mojo::JSON qw(encode_json decode_json true false);
use Mojo::IOLoop::Subprocess;
use Apache::Htpasswd;

sub hello {
    my $self = shift;
    $self->render(json => { message => 'hello', success => true });
}

sub db_list {
    my $self = shift;
    $self->render(json => { dblist => $self->app->model->db_list, success => true });
}

sub db_size {
    my $self = shift;
    my $dbname = $self->req->param('dbname');
    return $self->render(json => { success => false, dbname => $dbname }) unless $dbname;

    my $dbsize = $self->app->model->db_size($dbname);
    $self->render(json => { name => $dbname, size => $dbsize });
}

sub db_create {
    my $self = shift;
    my $dbname = $self->req->param('dbname');
    return $self->render(json => { success => false }) unless $dbname;

    my $res = $self->app->model->db_create($dbname);

    return $self->render(json => { success => true }) if $res;
    $self->render(json => { success => false });
}

sub db_drop {
    my $self = shift;
    my $dbname = $self->req->param('dbname');

    return $self->render(json => { success => false }) unless $dbname;

    my $res = $self->app->model->db_drop($dbname);

    return $self->render(json => { success => false }) unless $res;
    return $self->render(json => { success => true });
}

sub db_rename {
    my $self = shift;
    my $dbname = $self->req->param('dbname');
    my $newname = $self->req->param('newname');

    return $self->render(json => { success => false }) unless $dbname;
    return $self->render(json => { success => false }) unless $newname;

    my $res = $self->app->model->db_rename($dbname, $newname);

    return $self->render(json => { success => true }) if $res;
    return $self->render(json => { success => false });
}

sub db_copy {
    my $self = shift;
    my $dbname = $self->req->param('dbname');
    my $newname = $self->req->param('newname');
    return $self->render(json => { success => false }) unless $dbname;
    return $self->render(json => { success => false }) unless $newname;

    my $res = $self->app->model->db_copy($dbname, $newname);
    my $dbsize = $self->app->model->db_size($dbname) if $res;

    return $self->render(json => { success => true, dbsize => $dbsize}) if $res;
    return $self->render(json => { success => false});
}

sub db_exist {
    my $self = shift;
    my $dbname = $self->req->param('dbname');
    return $self->render(
            json => { success => false, dbname => '' }
    ) unless $dbname;
    my $res = $self->app->model->db_exist($dbname);
    my $dbsize = $self->app->model->db_size($dbname) if $res;
    return $self->render(
            json => { success => true, dbname => $dbname, dbsize => $dbsize}
    ) if $res;
    return $self->render(
            json => { success => false, dbname => $dbname }
    );
}

sub master_cb {
    my ($self, $master, $jobID, $magic, $status, $error, $result) = @_;

    return undef unless $master;
    return undef unless $jobID;
    return undef unless $magic;
    return undef unless $status;

    $error = 'noerr' unless $error;
    $result = 'success' unless $result;

    my $ua = Mojo::UserAgent->new;
    $ua = $ua->connect_timeout(15)->request_timeout(15);;

    my $param;
    $param .= "&master=$master";
    $param .= "&jobid=$jobID";
    $param .= "&magic=$magic";
    $param .= "&status=$status";
    $param .= "&result=success";

    my $url = "https://$master:3003/agent/job/cb?$param";
    $self->app->log->debug("master_cb: Master callback URL $url");

    my $tx = $ua->get($url);
    my $body;
    eval { $body = $tx->result->body };
    my $res;
    eval { $res = decode_json($body); };
    return $res if $res;
    return undef;
}


sub db_dump {
    my $self = shift;
    my $dbname = $self->req->param('dbname');

    my $storename = $self->req->param('store');
    my $storelogin = $self->req->param('storelogin');
    my $storepwd = $self->req->param('storepwd');

    my $master = $self->req->param('master');
    my $jobID = $self->req->param('jobid');
    my $magic = $self->req->param('magic');

    return $self->render(
            json => { success => false, dbname => '' }
    ) unless $dbname;
    return $self->render(
            json => { success => false, dbname => $dbname }
    ) unless $self->app->model->db_exist($dbname);

    my $subprocess = Mojo::IOLoop::Subprocess->new;
    $self->app->log->info("db_dump: Begin dump database $dbname in subprocess"); 
    $subprocess->run(
        sub {
            my $subprocess = shift;
            my $filename = $self->app->model->db_dump($dbname);
            do { 
                unlink $filename; 
                $self->master_cb($master, $jobID, $magic, "dumperr", "dumperr", 'mistake');
                return undef; 
            } unless $filename;

            my $resCB = $self->master_cb($master, $jobID, $magic, "dumped", "noerr", 'success');
            my $storeRes = $self->app->model->store_put($filename, $storename, $storelogin, $storepwd);

            do { 
                unlink $filename;
                $self->master_cb($master, $jobID, $magic, "storeerr", "storeerr", 'mistake');
                return undef; 
            } unless $storeRes;

            $self->master_cb($master, $jobID, $magic, "stored", "noerr", 'success');
            unlink $filename;
            return 1;
        },
        sub {
            my ($subprocess, $err, @results) = @_;
            my $pid = $subprocess->pid;
            $self->app->log->info("db_dump: End dump subprocess $pid for dump database $dbname");
        }
    );
    $subprocess->ioloop->start unless $subprocess->ioloop->is_running;
    $self->render(json => { success => true, $dbname => $dbname } );
}

sub db_restore {
    my $self = shift;


    my $req = $self->req;

    my $dataname = $req->param('dataname');
    my $storename = $req->param('store');
    my $storelogin = $req->param('storelogin');
    my $storepwd = $req->param('storepwd');

    my $newname = $req->param('newname');

    my $master = $req->param('master');
    my $jobID = $req->param('jobid');
    my $magic = $req->param('magic');

    my $m = $self->app->model;

    return $self->render(json => { success => false }) unless ($dataname and $storename and $storelogin);
    return $self->render(json => { success => false }) unless ($storepwd and $newname and $jobID and $master and $magic);
    return $self->render(json => { success => false }) unless $m->store_alive($storename);

    my $subprocess = Mojo::IOLoop::Subprocess->new;

    $subprocess->run(
        sub {
            my $subprocess = shift;
            $self->master_cb($master, $jobID, $magic, "dataget", "noerr", 'success');

            my $datafile = $m->store_get($dataname, $storename, $storelogin, $storepwd);

            unless ($datafile || -s $datafile) {
                unlink $dataname;
                $self->master_cb($master, $jobID, $magic, "geterr", "geterr", 'mistake');
                return undef;
            }

            $self->master_cb($master, $jobID, $magic, "datagot", "noerr", 'success');

            my $newdbname = $m->db_restore($datafile, $newname);

            unless ($newdbname) {
                unlink $dataname;
                $self->master_cb($master, $jobID, $magic, "resterr", "resterr", 'mistake');
                return undef; 
            };

            $self->master_cb($master, $jobID, $magic, "done", "noerr", 'success');
            1;

        },
        sub {
            my ($subprocess, $err, @results) = @_;
            my $pid = $subprocess->pid;
            $self->app->log->info("db_restore: End restore subprocess $pid for dataset $dataname");
        }
    );
    $subprocess->ioloop->start unless $subprocess->ioloop->is_running;

    $self->render(json => { success => true });
}

sub role_list {
    my $self = shift;
    $self->render(json => { success => true, role => $self->app->model->role_list });
}

sub role_exist {
    my $self = shift;
    my $rolename = $self->req->param('rolename');

    return $self->render(json => { success => false, rolename => undef })  unless $rolename;

    my $res = $self->app->model->role_exist($rolename);

    return $self->render(json => { success => true, rolename => $rolename }) if $res;
    $self->render(json => { success => false, rolename => $rolename });
}

sub role_password {
    my $self = shift;
    my $rolename = $self->req->param('rolename');

    return $self->render(json => { success => false, rolename => undef }) unless $rolename;
    # dummy
    $self->render(json => { success => true, rolename => $rolename });
}

sub role_create {
    my $self = shift;
    my $rolename = $self->req->param('rolename');
    return $self->render(json => { success => false, rolename => undef })  unless $rolename;
    $self->render(json => { success => true, rolename => $rolename });
}

sub role_drop {
    my $self = shift;
    my $rolename = $self->req->param('rolename');

    return $self->render(json => { success => false, rolename => undef })  unless $rolename;
    $self->render(json => { success => true, rolename => $rolename });
}

1;

#-----------
#--- APP ---
#-----------

package PGagent;

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

use POSIX qw(setuid setgid tzset tzname strftime);
use Mojo::Server::Prefork;
use Mojo::IOLoop::Subprocess;
use Mojo::Util qw(md5_sum b64_decode getopt dumper);
use Sys::Hostname qw(hostname);
use File::Basename qw(basename dirname);
use Apache::Htpasswd;
use Cwd qw(getcwd abs_path);
use EV;

my $appname = 'pgdumper';

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
my $app = $server->build_app('PGagent');
$app = $app->controller_class('PGagent::Controller');

$app->secrets(['6d578e43ba88260e0375a1a35fd7954b']);
$app->static->paths(['@APP_LIBDIR@/public']);
$app->renderer->paths(['@APP_LIBDIR@/templs']);

$app->config(conffile => $conffile || '@APP_CONFDIR@/pgagent.conf');
$app->config(pwdfile => '@APP_CONFDIR@/pgagent.pw');
$app->config(logfile => '@APP_LOGDIR@/pgagent.log');
$app->config(loglevel => 'debug');
$app->config(pidfile => '@APP_RUNDIR@/pgagent.pid');
$app->config(crtfile => '@APP_CONFDIR@/pgagent.crt');
$app->config(keyfile => '@APP_CONFDIR@/pgagent.key');

$app->config(user => $user || '@APP_USER@');
$app->config(group => $group || '@APP_GROUP@');

$app->config(listenaddr4 => '0.0.0.0');
$app->config(listenaddr6 => '[::]');
$app->config(listenport => '3001');

$app->config(tmpdir => '/tmp');

$app->config(pghost => '127.0.0.1');
$app->config(pguser => 'postgres');
$app->config(pgpwd => 'password');


if (-r $app->config('conffile')) {
    $app->log->debug("Load configuration from ".$app->config('conffile'));
    $app->plugin('JSONConfig', { file => $app->config('conffile') });
}

#---------------
#--- HELPERS ---
#---------------

$app->helper('reply.exception' => sub { my $c = shift; return $c->rendered(404); });
$app->helper('reply.not_found' => sub { my $c = shift; return $c->rendered(404); });


$app->helper(
    model => sub {
        my $db = PGagent::DB->new(
                        hostname => $app->config("pghost"),
                        username => $app->config("pguser"),
                        password => $app->config("pgpwd"),
                        database => 'postgres'
        );
        state $model = PGagent::Model->new($app, $db);
    }
);


#--------------
#--- ROUTES ---
#--------------

my $r = $app->routes;

$r->add_condition(
    auth => sub {
        my ($route, $c) = @_;
        my $log = $c->app->log;
        my $authstr = $c->req->headers->authorization;
        my $pwdfile = $c->app->config('pwdfile');

        my $a = PGagent::BasicAuth->new($pwdfile);

        $log->info("Try auth user ". $a->username($authstr));
        $a->auth($authstr);

    }
);

$r->any('/hello')->to('controller#hello');
$r->any('/conf/dump')->over('auth')->to('controller#conf_dump');

$r->any('/db/list')     ->over('auth')->to('controller#db_list');
$r->any('/db/create')   ->over('auth')->to('controller#db_create');
$r->any('/db/drop')     ->over('auth')->to('controller#db_drop');
$r->any('/db/rename')   ->over('auth')->to('controller#db_rename');
$r->any('/db/copy')     ->over('auth')->to('controller#db_copy');
$r->any('/db/size')     ->over('auth')->to('controller#db_size');
$r->any('/db/dump')     ->over('auth')->to('controller#db_dump');
$r->any('/db/restore')  ->over('auth')->to('controller#db_restore');
$r->any('/db/exist')    ->over('auth')->to('controller#db_exist');
$r->any('/db/owner')    ->over('auth')->to('controller#db_owner');


$r->any('/role/list')   ->over('auth')->to('controller#role_list');
$r->any('/role/exist')  ->over('auth')->to('controller#role_exist');
$r->any('/role/password')->over('auth')->to('controller#role_password');
$r->any('/role/create') ->over('auth')->to('controller#role_create');
$r->any('/role/drop')   ->over('auth')->to('controller#role_drop');


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
    my $d = PGagent::Daemon->new;
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
