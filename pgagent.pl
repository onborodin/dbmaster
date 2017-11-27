#!/usr/bin/env perl

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
use Mojo::JSON qw(encode_json decode_json);
use POSIX;
use Socket;

sub new {
    my ($class, $app, $pghost, $username, $password) = @_;
    my $self = {
        app => $app,
        pghost => $pghost,
        dsn => "dbi:Pg:dbname=postgres;host=$pghost",
        username => $username,
        password => $password,
    };
    bless $self, $class;
    return $self;
}

sub username {
    return shift->{username}; 
}
sub password {
    return shift->{password}; 
}
sub dsn {
    return shift->{dsn}; 
}
sub pghost {
    return shift->{pghost}; 
}
sub app {
    return shift->{app}; 
}

sub storeAlive {
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

sub storePut {
    my ($self, $datafile, $storename, $storeuser, $storepwd) = @_;
    my $ua = Mojo::UserAgent->new(max_redirects => 5);
    $ua = $ua->connect_timeout(15)->request_timeout(15);;

    return undef unless $datafile;
    return undef unless $storename;

    return undef unless -f $datafile;
    return undef unless -r $datafile;
    return undef unless $self->storeAlive($storename);

    $self->app->log->info("storePut: Start upload $datafile to store $storename");
    my $tx = $ua->post("https://$storeuser:$storepwd\@$storename:3002/data/put" =>
                            form => { data => { file => $datafile }} );
    $self->app->log->info("storePut: End upload $datafile to store $storename");

    my $res;
    eval { $res = $tx->result; };
    return $res->body if $res;
    return undef;
}

sub storeGet {
    my ($self, $dataset, $storename, $storeuser, $storepwd) = @_;
    return undef unless $dataset;
    return undef unless $storename;
    return undef unless $self->storeAlive($storename);

    $storeuser = 'undef' unless $storeuser;
    $storepwd = 'undef' unless $storepwd;

    my $tmpdir = $self->app->config('tmpdir');

    return undef unless -d $tmpdir;
    return undef unless -w $tmpdir;

    my $datafile = "$tmpdir/rest".."$dataset";
    $self->app->log->info("storeGet: Start download $dataset from store $storename to $datafile");

    my $ua = Mojo::UserAgent->new(max_redirects => 5);
    $ua = $ua->connect_timeout(30)->request_timeout(30);;

    my $tx = $ua->get("https://$storeuser:$storepwd\@$storename:3002/data/get?dataname=$dataset");
    $tx->result->content->asset->move_to($datafile);
    $self->app->log->info("storeGet: End download $dataset from store $storename");

    return $datafile if -r $datafile;
    unlink $datafile; return undef;
}


#-----------------
#--- DB MODEL ----
#-----------------

sub dbExist {
    my ($self, $dbname) = @_;
    return undef unless $dbname;
    my $dblist = $self->dbList;
    foreach my $db (@{$dblist}) {
        return 1 if $db->{"name"} eq $dbname;
    }
    return undef;
}

sub dbSize {
    my ($self, $dbname) = @_;
    return undef unless $dbname;
    return -1 unless $self->dbExist($dbname);

    my $db = DBI->connect($self->dsn, $self->username, $self->password) or return -1;
    my $query = "select pg_database_size('$dbname');";
    my $sth = $db->prepare($query);
    my $rows = $sth->execute;
    my $row = $sth->fetchrow_array;

    $sth->finish;
    $db->disconnect;
    my $dbsize = int($row);
    return $dbsize;
}

sub dbList {
    my $self = shift;
    my $db = DBI->connect($self->dsn, $self->username, $self->password) or return -1;

    my $query = "select d.datname as name, pg_database_size(d.datname) as size, u.usename as owner, 
                s.numbackends as numbackends
                from pg_database d, pg_user u, pg_stat_database s 
                where d.datdba = u.usesysid and d.datname = s.datname order by d.datname;";

    my $sth = $db->prepare($query);
    my $rows = $sth->execute or return undef;
    my @dblist;

    while (my $row = $sth->fetchrow_hashref) {
        push @dblist, $row;
    }

    $sth->finish;
    $db->disconnect;
    return \@dblist;
}

sub dbCreate {
    my ($self, $dbname) = @_;
    return undef unless $dbname;
    return 1 if $self->dbExist($dbname);

    my $db = DBI->connect($self->dsn, $self->username, $self->password) or return undef;
    my $query = "create database $dbname;";
    my $rows = $db->do($query) or return undef;

    $db->disconnect;
    return 1 if $rows;
    return undef;
}

sub dbDrop {
    my ($self, $dbname) = @_;
    return undef unless $self->dbExist($dbname);
    return undef unless $dbname;

    my $db = DBI->connect($self->dsn, $self->username, $self->password) or return undef;
    my $query = "drop database $dbname;";
    my $rows = $db->do($query);
    $db->disconnect;

    return 1 if $rows;
    return undef;
}

sub dbRename {
    my ($self, $dbname, $newname) = @_;
    return undef unless $self->dbExist($dbname);
    return undef unless $dbname;
    return undef unless $newname;

    my $db = DBI->connect($self->dsn, $self->username, $self->password) or return undef;
    my $query = "alter database $dbname rename to $newname;";
    my $rows = $db->do($query);
    $db->disconnect;

    return 1 if $rows;
    return undef;
}

sub dbCopy {
    my ($self, $dbname, $newname) = @_;
    return undef unless $dbname;
    return undef unless $newname;
    return undef unless $self->dbExist($dbname);
    return undef if $self->dbExist($newname);
    my $db = DBI->connect($self->dsn, $self->username, $self->password) or return undef;
    my $query = "create database $newname template $dbname;";
    my $rows = $db->do($query) or return undef;
    $db->disconnect;
    return 1 if $rows;
    return undef;
}


sub dbDump {
    my ($self, $dbname) = @_;

    return undef unless $dbname;
    return undef unless $self->dbExist($dbname);

    my $tmpdir = "/".$self->app->config("tmpdir");

    do {
        $self->app->log->error("Error: tmpdir $tmpdir not exist");
        return undef; 
    } unless -d $tmpdir;

    do {
        $self->app->log->error("Error: Cannot write to tmpdir $tmpdir");
        return undef; 
    } unless -w $tmpdir;

    my $hostname = $self->app->config("hostname");
    my $timestamp = strftime("%Y%m%d-%H%M%S-%Z", localtime(time));
    my $dbdump = "$tmpdir/$dbname--$timestamp--$hostname.sqlz";

    my $password = $self->password;
    my $pghost = $self->pghost;
    my $username = $self->username;

    my $dbsize = $self->dbSize($dbname);

    $self->app->log->info("dbDump: Start dump database $dbname with db size $dbsize");
    my $out = qx/PGPASSWORD=$password pg_dump -h $pghost -U $username -Fc -f $dbdump $dbname 2>&1/;
    my $retcode = $?;

    my $dumpstat = stat($dbdump);
    my $dumpsize = $dumpstat->size;
    $self->app->log->info("dbDump: End dump database $dbname to $dbdump with size $dumpsize");

    return $dbdump if $retcode == 0;
    return undef;
}

sub dbRestore {
    my ($self, $filename, $dbname) = @_;
    return undef unless $dbname;
    return undef unless $filename;
    return undef unless -r $filename;
    return undef unless -s $filename;
    do {
        $self->app->log->warning("+++ dbRestore: Database $dbname yet exist");
        return undef;
    } if $self->dbExist($dbname);
    do { 
        $self->app->log->warning("!!! dbRestore: Cannot create database $dbname");
        return undef;
    } unless $self->dbCreate($dbname);

    $self->app->log->info("--- dbRestore: Start restore database $dbname from $filename");

    my $password = $self->password;
    my $pghost = $self->pghost;
    my $username = $self->username;

    my $out = qx/PGPASSWORD=$password pg_restore -j 4 -h $pghost -U $username -Fc -d $dbname $filename 2>&1/;
    my $retcode = $?;

    do {
        $self->app->log->info("!!! dbRestore: Error restore $dbname");
        $self->dbDrop($dbname) if $self->dbExist($dbname);
    } if $retcode > 1;

    my $dbsize = $self->dbSize($dbname);
    $self->app->log->info("--- dbRestore: End restore database $dbname with size $dbsize");
    return $dbname;
}

#-------------------
#--- ROLE MODEL ----
#-------------------

sub dbOwner {
    my ($self, $dbname) = @_;
    return undef unless $dbname;
    return undef unless $self->dbExist($dbname);

    my $db = DBI->connect($self->dsn, $self->username, $self->password) or return undef;
    my $query = "select u.usename as username, d.datname as dbname 
                        from pg_database d, pg_user u 
                        where d.datdba = u.usesysid and d.datname = '$dbname' limit 1;";
    my $sth = $db->prepare($query);
    my $rows = $sth->execute  or return undef;
    my $row = $sth->fetchrow_hashref;
    $db->disconnect;
    return $row if $row;
    return undef;
}

sub roleList {
    my $self = shift;
    my $db = DBI->connect($self->dsn, $self->username, $self->password) or return undef;
    my $query = "select usename as rolename from pg_user;";
    my $sth = $db->prepare($query);
    my $rows = $sth->execute  or return undef;
    my @rolelist;
    while (my $row = $sth->fetchrow_hashref) {
        push @rolelist, $row;
    }
    $sth->finish;
    $db->disconnect;
    return \@rolelist;
}

sub roleExist {
    my ($self, $rolename) = @_;
    return undef unless $rolename;
    my $rolelist = $self->roleList;
    foreach my $role (@{$rolelist}) {
        return 1 if $rolename eq $role->{'rolename'};
    }
    return undef;
}

sub roleCreate {
    my ($self, $rolename, $password) = @_;
    return undef unless $password;
    return undef unless $rolename;
    return undef unless $self->roleExist($rolename);

    my $db = DBI->connect($self->dsn, $self->username, $self->password) or return undef;
    my $query = "create user '$rolename' encrypted password '$password';";
    my $rows = $db->do($query);
    $db->disconnect;

    return 1 if $rows;
    return undef;
}

sub roleDrop {
    my ($self, $rolename) = @_;
    return undef unless $rolename;
    return undef unless $self->roleExist($rolename);

    my $db = DBI->connect($self->dsn, $self->username, $self->password) or return undef;
    my $query = "drop user '$rolename';";
    my $rows = $db->do($query);
    $db->disconnect;

    return 1 if $rows;
    return undef;
}

sub rolePassword {
    my ($self, $rolename, $password) = @_;
    return undef unless $password;
    return undef unless $rolename;
    return undef unless $self->roleExist($rolename);

    my $db = DBI->connect($self->dsn, $self->username, $self->password) or return undef;
    my $query = "alter role $rolename encrypted password '$password';";
    my $rows = $db->do($query);
    $db->disconnect;

    return 1 if $rows;
    return undef;
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
use Mojo::JSON qw(encode_json decode_json);
use Mojo::IOLoop::Subprocess;
use Apache::Htpasswd;

sub hello {
    my $self = shift;
    $self->render( json => { message => 'hello', result => "success" } );
}

sub confDump {
    my $self = shift;
    $self->render( json => $self->app->config );
}

sub dbList {
    my $self = shift;
    $self->render(
        json => { dblist => $self->app->model->dbList }
    );
}

sub dbSize {
    my $self = shift;
    my $dbname = $self->req->param('dbname');
    return $self->render(
            json => { result => "mistake", dbname => $dbname }
    ) unless $dbname;
    my $dbsize = $self->app->model->dbSize($dbname);
    $self->render( 
        json => { name => $dbname, size => $dbsize }
    );
}

sub dbCreate {
    my $self = shift;
    my $dbname = $self->req->param('dbname');
    return $self->render(
            json => { result => "mistake", dbname => $dbname }
        ) unless $dbname;
    my $res = $self->app->model->dbCreate($dbname);

    return $self->render(
            json => { result => "success", dbname => $dbname }
    ) if $res;

    return $self->render(
        json => { result => "mistake", dbname => $dbname }
    );
}

sub dbDrop {
    my $self = shift;
    my $dbname = $self->req->param('dbname');
    return $self->render(
            json => { result => "mistake", dbname => $dbname }
        ) unless $dbname;
    my $res = $self->app->model->dbDrop($dbname);
    return $self->render(
            json => { result => "success", dbname => $dbname }
    ) if $res;
    return $self->render(
            json => { result => "mistake", dbname => $dbname }
    );
}

sub dbRename {
    my $self = shift;
    my $dbname = $self->req->param('dbname');
    my $newname = $self->req->param('newname');
    return $self->render(
            json => { result => "mistake", dbname => $dbname }
    ) unless $dbname;
    return $self->render(
            json => { result => "mistake", dbname => $dbname }
    ) unless $newname;
    my $res = $self->app->model->dbRename($dbname, $newname);

    my $dbsize = $self->app->model->dbSize($dbname) if $res;

    return $self->render(
            json => { result => "success", dbname => $dbname, dbsize => $dbsize}
    ) if $res;
    return $self->render(
            json => { result => "mistake", dbname => $dbname }
    );
}


sub dbCopy {
    my $self = shift;
    my $dbname = $self->req->param('dbname');
    my $newname = $self->req->param('newname');
    return $self->render(
            json => { result => "mistake", dbname => $dbname }
    ) unless $dbname;
    return $self->render(
            json => { result => "mistake", dbname => $dbname }
    ) unless $newname;
    my $res = $self->app->model->dbCopy($dbname, $newname);
    my $dbsize = $self->app->model->dbSize($dbname) if $res;
    return $self->render(
            json => {result => "success", dbname => $dbname, dbsize => $dbsize}
    ) if $res;
    return $self->render(
        json => { result => "mistake", dbname => $dbname }
    );
}

sub dbExist {
    my $self = shift;
    my $dbname = $self->req->param('dbname');
    return $self->render(
            json => { result => "mistake", dbname => '' }
    ) unless $dbname;
    my $res = $self->app->model->dbExist($dbname);
    my $dbsize = $self->app->model->dbSize($dbname) if $res;
    return $self->render(
            json => { result => "success", dbname => $dbname, dbsize => $dbsize}
    ) if $res;
    return $self->render(
            json => { result => "mistake", dbname => $dbname }
    );
}

sub masterCB {
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
    $self->app->log->debug("masterCB: Master callback URL $url");

    my $tx = $ua->get($url);
    my $body;
    eval { $body = $tx->result->body };
    my $res;
    eval { $res = decode_json($body); };
    return $res if $res;
    return undef;
}


sub dbDump {
    my $self = shift;
    my $dbname = $self->req->param('dbname');

    my $storename = $self->req->param('store');
    my $storelogin = $self->req->param('storelogin');
    my $storepwd = $self->req->param('storepwd');

    my $master = $self->req->param('master');
    my $jobID = $self->req->param('jobid');
    my $magic = $self->req->param('magic');

    return $self->render(
            json => { response => "mistake", dbname => '' }
    ) unless $dbname;
    return $self->render(
            json => { response => "mistake", dbname => $dbname }
    ) unless $self->app->model->dbExist($dbname);

    my $subprocess = Mojo::IOLoop::Subprocess->new;
    $self->app->log->info("dbDump: Begin dump database $dbname in subprocess"); 
    $subprocess->run(
        sub {
            my $subprocess = shift;
            my $filename = $self->app->model->dbDump($dbname);
            do { 
                unlink $filename; 
                $self->masterCB($master, $jobID, $magic, "dumperr", "dumperr", "mistake");
                return undef; 
            } unless $filename;

            my $resCB = $self->masterCB($master, $jobID, $magic, "dumped", "noerr", "success");
            my $storeRes = $self->app->model->storePut($filename, $storename, $storelogin, $storepwd);

            do { 
                unlink $filename;
                $self->masterCB($master, $jobID, $magic, "storeerr", "storeerr", "mistake");
                return undef; 
            } unless $storeRes;

            $self->masterCB($master, $jobID, $magic, "stored", "noerr", "success");
            unlink $filename;
            return 1;
        },
        sub {
            my ($subprocess, $err, @results) = @_;
            my $pid = $subprocess->pid;
            $self->app->log->info("dbDump: End dump subprocess $pid for dump database $dbname");
        }
    );
    $subprocess->ioloop->start unless $subprocess->ioloop->is_running;
    $self->render(json => { result => "success", $dbname => $dbname } );
}

sub dbRestore {
    my $self = shift;
    my $dataname = $self->req->param('dataname');

    my $storename = $self->req->param('store');
    my $storelogin = $self->req->param('storelogin');
    my $storepwd = $self->req->param('storepwd');

    my $newname = $self->req->param('newname');

    my $master = $self->req->param('master');
    my $jobID = $self->req->param('jobid');
    my $magic = $self->req->param('magic');

    return $self->render(
            json => { response => "mistake", dataname => '' }
    ) unless ($dataname and $storename and $storelogin);

    return $self->render(
            json => { response => "mistake", dataname => '' }
    ) unless ($storepwd and $newname and $jobID and $master and $magic);

    return $self->render(
        json => { response => "mistake", dataname => '' }
    ) unless $self->app->model->storeAlive($storename);

    my $subprocess = Mojo::IOLoop::Subprocess->new;
    $self->app->log->info("dbRestore: Begin restore db from $dataname in subprocess"); 

    $subprocess->run(
        sub {
            my $subprocess = shift;
            $self->masterCB($master, $jobID, $magic, "dataget", "noerr", "success");

            my $datafile = $self->app->model->storeGet($dataname, $storename, $storelogin, $storepwd);

            do {
                unlink $dataname;
                $self->masterCB($master, $jobID, $magic, "geterr", "geterr", "mistake");
                return undef; 
            } unless ($datafile || -s $datafile);
            $self->masterCB($master, $jobID, $magic, "datagot", "noerr", "success");

            my $newdbname = $self->app->model->dbRestore($datafile, $newname);

            do {
                unlink $dataname;
                $self->masterCB($master, $jobID, $magic, "resterr", "resterr", "mistake");
                return undef; 
            } unless $newdbname;

            $self->masterCB($master, $jobID, $magic, "done", "noerr", "success");
            return 1;
        },
        sub {
            my ($subprocess, $err, @results) = @_;
            my $pid = $subprocess->pid;
            $self->app->log->info("dbRestore: End restore subprocess $pid for dataset $dataname");
        }
    );
    $subprocess->ioloop->start unless $subprocess->ioloop->is_running;
    $self->render(
        json => { result => "success", dataname => $dataname }
    );
}

sub roleList {
    my $self = shift;
    $self->render(
        json => { result => "success", role => $self->app->model->roleList }
    );
}

sub roleExist {
    my $self = shift;
    my $rolename = $self->req->param('rolename');

    return $self->render(
            json => { result => "mistake", rolename => undef }
    )  unless $rolename;

    my $res = $self->app->model->roleExist($rolename);

    return $self->render(
            json => { result => "success", rolename => $rolename }
    ) if $res;

    $self->render(
            json => { result => "mistake", rolename => $rolename }
    );
}

sub rolePassword {
    my $self = shift;
    my $rolename = $self->req->param('rolename');

    return $self->render(
            json => { result => "mistake", rolename => undef }
    ) unless $rolename;

    $self->render(
            json => { result => "success", rolename => $rolename }
    );
}

sub roleCreate {
    my $self = shift;
    my $rolename = $self->req->param('rolename');
    return $self->render(
            json => { result => "mistake", rolename => undef }
    )  unless $rolename;
    $self->render(
            json => { result => "success", rolename => $rolename }
    );
}

sub roleDrop {
    my $self = shift;
    my $rolename = $self->req->param('rolename');

    return $self->render(
            json => { result => "mistake", rolename => undef }
    )  unless $rolename;

    $self->render(
            json => { result => "success", rolename => $rolename }
    );
}

1;

#------------
#--- APP ---
#------------

package PGagent;

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
use Sys::Hostname qw(hostname);
use File::Basename qw(basename dirname);
use Apache::Htpasswd;
use Cwd qw(getcwd abs_path);

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
my $app = $server->build_app('PGagent');
$app = $app->controller_class('PGagent::Controller');


$app->config(
    hostname => hostname,
    tmpdir => $tmpdir || "/tmp",
    listenIPv4 => "0.0.0.0",
    listenIPv6 => "[::]",
    listenPort => "3001",
    pghost => "127.0.0.1",
    pguser => "postgres",
    pgpasswd => "password",
    pwdfile => $pwdfile || "@APP_CONFDIR@/$appname.pw",
    pidfile => $pidfile || "@APP_RUNDIR@/$appname.pid",
    logfile => $logfile || "@APP_LOGDIR@/$appname.log",
    conffile => "@APP_CONFDIR@/$appname.conf",
    maxrequestsize => 1024*1024*1024,
    tlscert => "@APP_CONFDIR@/$appname.crt",
    tlskey => "@APP_CONFDIR@/$appname.key",
    appuser => $user || "@APP_USER@",
    appgroup => $group || "@APP_GROUP@",
    mode => 'production',
    loglevel => $loglevel || 'info',
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
        state $model = PGagent::Model->new(
            $app,
            $app->config("pghost"),
            $app->config("pguser"),
            $app->config("pgpasswd")
        );
    }
);

my $r = $app->routes;

$r->add_condition(
    auth => sub {
        my ($route, $c, $captures, $hash) = @_;
        my $authStr = $c->req->headers->authorization;
        return undef unless $authStr;

        my ($authType, $encAuthPair) = split / /, $authStr;
        return undef unless ($authType eq 'Basic' && $encAuthPair);

        my ($username, $password) = split /:/, b64_decode($encAuthPair);
        $c->app->log->debug("Receive auth pair: '$username:$password'");
        return undef unless ($username && $password);

        my $passwdFile = $c->app->config('pwdfile');
        do { 
            $c->app->log->error("Cannot read password file '$passwdFile'");
            return undef;
        } unless -r $passwdFile;

        my $result = undef;
        eval {
            my $ht = Apache::Htpasswd->new({ passwdFile => $passwdFile, ReadOnly => 1 });
            $result = $ht->htCheckPassword($username, $password);
        };
        do { $c->app->log->debug("Auth module error: $@"); return undef; } if $@;

        return 1 if $result;
        $c->app->log->info("Bad auth from ".$c->tx->remote_address);
        return undef;
    }
);

$r->any('/hello')->to('Controller#hello');
$r->any('/conf/dump')->over('auth')->to('Controller#confDump');

$r->any('/db/list')->over('auth')->to('Controller#dbList');
$r->any('/db/create')->over('auth')->to('Controller#dbCreate');
$r->any('/db/drop')->over('auth')->to('Controller#dbDrop');
$r->any('/db/rename')->over('auth')->to('Controller#dbRename');
$r->any('/db/copy')->over('auth')->to('Controller#dbCopy');
$r->any('/db/size')->over('auth')->to('Controller#dbSize');
$r->any('/db/dump')->over('auth')->to('Controller#dbDump');
$r->any('/db/restore')->over('auth')->to('Controller#dbRestore');
$r->any('/db/exist')->over('auth')->to('Controller#dbExist');
$r->any('/db/owner')->over('auth')->to('Controller#dbOwner');


$r->any('/role/list')->over('auth')->to('Controller#roleList');
$r->any('/role/exist')->over('auth')->to('Controller#roleExist');
$r->any('/role/password')->over('auth')->to('Controller#rolePassword');
$r->any('/role/create')->over('auth')->to('Controller#roleCreate');
$r->any('/role/drop')->over('auth')->to('Controller#roleDrop');

$app->mode($app->config("mode"));
$app->secrets([ md5_sum(localtime(time)) ]);

$app->hook(before_dispatch => sub {
        my $c = shift;

        my $remoteIPaddr = $c->tx->remote_address;
        my $method = $c->req->method;

        my $base = $c->req->url->base->to_string;
        my $path = $c->req->url->path->to_string;

        my $loglevel = $c->app->log->level;
        unless ($loglevel eq 'debug') {
            $c->app->log->info("$method $base$path from $remoteIPaddr");
        }
        if ($loglevel eq 'debug') {
            my $url = $c->req->url->to_abs->to_string;
            $c->app->log->debug("$method $url from $remoteIPaddr");
        }
});

$app->log(Mojo::Log->new(level => $app->config('loglevel')));


$app->helper('reply.exception' => sub { my $c = shift; return $c->rendered(404); });
$app->helper('reply.not_found' => sub { my $c = shift; return $c->rendered(404); });

my $tlsParam .= '?';
$tlsParam .= 'cert='.$tlscert;
$tlsParam .= '&key='.$tlskey;

my $listenPort = $app->config('listenPort');
my $listenIPv4 = $app->config('listenIPv4');
my $listenIPv6 = $app->config('listenIPv6');

$server->listen([
    "https://$listenIPv4:$listenPort$tlsParam",
]);

$server->heartbeat_interval(3);
$server->heartbeat_timeout(60);
$server->pid_file($app->config('pidfile'));

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
                $app->log->info('Catch HUP signal'); 
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