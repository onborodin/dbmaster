#!@perl@

package aConfig;

use strict;
use warnings;

sub new {
    my ($class, $file) = @_;
    my $self = {
        file => $file
    };
    bless $self, $class;
    $self;
}

sub file {
    my ($self, $name) = @_;
    return $self->{'file'} unless $name;
    $self->{'file'} = $name;
    $self;
}

sub read {
    my $self = shift;
    return undef unless -r $self->file;
    open my $fh, '<', $self->file;
    my %res;
    while (my $line = readline $fh) {
        chomp $line;
        $line =~ s/^\s+//g;

        next if $line =~ /^#/;
        next if $line =~ /^;/;
        next unless $line =~ /[=:]/;

        $line =~ s/[\"\']//g;
        my ($key, $rawvalue) = split(/==|=>|[=:]/, $line);
        next unless $rawvalue and $key;

        my ($value, $comment) = split(/[#;,]/, $rawvalue);

        $key =~ s/^\s+|\s+$//g;
        $value =~ s/^\s+|\s+$//g;

        $res{$key} = $value;
    }
    close $fh;
    \%res;
}

1;

#----------
#--- DB ---
#----------

package aDBI;

use strict;
use warnings;
use DBI;
use DBD::Pg;

sub new {
    my ($class, %args) = @_;
    my $self = {
        hostname => $args{hostname} || '',
        username => $args{username} || '',
        password => $args{password} || '',
        database => $args{database} || '',
        engine => $args{engine} || 'SQLite',
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
    my $engine = $self->engine;
    my $database = $self->database;
    my $hostname = $self->hostname;
    my $dsn = "dbi:$engine:dbname=$database;host=$hostname";
    my $dbi;
#    eval {
        $dbi = DBI->connect($dsn, $self->username, $self->password, {
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1
        });
#    };
    $self->error($@);
    return undef if $@;

    my $sth;
#    eval {
        $sth = $dbi->prepare($query);
#    };
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

sub exec1 {
    my ($self, $query) = @_;
    return undef unless $query;

    my $dsn = 'dbi:'.$self->engine.
                ':dbname='.$self->database.
                ';host='.$self->hostname;
    my $dbi;
#    eval {
        $dbi = DBI->connect($dsn, $self->username, $self->password, {
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1
        });
#    };
    $self->error($@);
    return undef if $@;

    my $sth;
#    eval {
        $sth = $dbi->prepare($query);
#    };
    $self->error($@);
    return undef if $@;

    my $rows = $sth->execute;
    my $row = $sth->fetchrow_hashref;

    $sth->finish;
    $dbi->disconnect;
    $row;
}

sub do {
    my ($self, $query) = @_;
    return undef unless $query;
    my $dsn = 'dbi:'.$self->engine.
                ':dbname='.$self->database.
                ';host='.$self->hostname;
    my $dbi;
#    eval {
        $dbi = DBI->connect($dsn, $self->username, $self->password, {
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1
        });
#    };
    $self->error($@);
    return undef if $@;
    my $rows;
#    eval {
        $rows = $dbi->do($query);
#    };
    $self->error($@);
    return undef if $@;

    $dbi->disconnect;
    $rows*1;
}

1;

#--------------
#--- MASTER ---
#--------------

package aMaster;

use strict;
use warnings;
use Digest::SHA qw(sha512_base64);

sub new {
    my ($class, $db) = @_;
    my $self = { db => $db};
    bless $self, $class;
    return $self;
}

sub db {
    my ($self, $db) = @_;
    return $self->{db} unless $db;
    $self->{db} = $db;
    $self;
}

# --- AGENT ---

sub agent_exist {
    my ($self, $name) = @_;
    return undef unless $name;
    my $res = $self->db->exec1("select id from agent where name = '$name' order by id limit 1");
    $res->{id};
}

sub agent_profile {
    my ($self, $id) = @_;
    return undef unless $id;
    my $row = $self->db->exec1("select * from agent where agent.id = $id limit 1");
    $row;
}

sub agent_nextid {
    my $self = shift;
    my $res = $self->db->exec1("select id from agent order by id desc limit 1");
    my $id = $res->{id} || 0;
    $id += 1;
}

sub agent_add {
    my ($self, $name, $login, $quota) = @_;
    return undef unless $name;
    return undef unless $login;
    return undef unless $quota;
    return undef if $self->agent_exist($name);
    my $next_id = $self->agent_nextid;

    $self->db->do("insert into agent (id, name, login, password) values ($next_id, '$name', '$login', '$password')");
    $self->agent_exist($name);
}

sub agent_list {
    my $self = shift;
    $self->db->exec("select * from agent order by name");
}

sub agent_update {
    my ($self, $id, %args) = @_;
    return undef unless $id;

    my $prof = $self->agent_profile($id);
    return undef unless $prof;

    my $name = $args{name} || $prof->{name};
    my $name = $args{login} || $prof->{login};
    my $name = $args{password} || $prof->{password};

    $self->db->do("update agent set name = '$name', login = $login, password = $password where id = $id");
    my $res = $self->agent_profile($id);
    return undef unless $res->{name} eq $name;
    $id;
}

sub agent_delete {
    my ($self, $id) = @_;
    return undef unless $id;
    $self->db->do("delete from agent where id = $id");
    return undef if $self->agent_profile($id);
    $id;
}

1;

#--------------
#--- DAEMON ---
#--------------

package aDaemon;

use strict;
use warnings;
use POSIX qw(getpid setuid setgid geteuid getegid);
use Cwd qw(cwd getcwd chdir);
use Mojo::Util qw(dumper);

sub new {
    my ($class, $user, $group)  = @_;
    my $self = {
        user => $user,
        group => $group
    };
    bless $self, $class;
    return $self;
}

sub fork {
    my $self = shift;

    my $pid = fork;
    if ($pid > 0) {
        exit;
    }
    chdir("/");

    my $uid = getpwnam($self->{user}) if $self->{user};
    my $gid = getgrnam($self->{group}) if $self->{group};

    setuid($uid) if $uid;
    setgid($gid) if $gid;

    open(my $stdout, '>&', STDOUT); 
    open(my $stderr, '>&', STDERR);
    open(STDOUT, '>>', '/dev/null');
    open(STDERR, '>>', '/dev/null');
    getpid;
}

1;


#--------------------
#--- CONTROLLER 1 ---
#--------------------

package DBmaster::Controller;

use strict;
use warnings;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(dumper);
use Mojo::JSON qw(decode_json encode_json);

use Apache::Htpasswd;

# --- AUTH ---

sub pwfile {
    my ($self, $pwfile) = @_;
    return $self->app->config('pwfile') unless $pwfile;
    $self->app->config(pwfile => $pwfile);
}

sub log {
    my ($self, $log) = @_;
    return $self->app->log unless $log;
    $self->app->log = $log;
}

sub ucheck {
    my ($self, $username, $password) = @_;
    return undef unless $password;
    return undef unless $username;
    my $pwfile = $self->pwfile or return undef;
    my $res = undef;
    eval {
        my $ht = Apache::Htpasswd->new({ passwdFile => $pwfile, ReadOnly => 1 });
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

# --- HELLO ---

sub hello {
    my $self = shift;
    $self->render(template => 'hello');
}

# --- AGENT ---

sub agent_list {
    my $self = shift;
    $self->render(template => 'agent-list');
}
sub agent_add_form {
    my $self = shift;
    $self->render(template => 'agent-add-form');
}
sub agent_add_handler {
    my $self = shift;
    $self->render(template => 'agent-add-handler');
}
sub agent_update_form {
    my $self = shift; 
    $self->render(template => 'agent-update-form');
}

sub agent_update_handler {
    my $self = shift;
    $self->render(template => 'agent-update-handler');
}

sub agent_delete_form {
    my $self = shift;
    $self->render(template => 'agent-delete-form');
}

sub agent_delete_handler {
    my $self = shift;
    $self->render(template => 'agent-delete-handler');
}

1;

#-----------
#--- APP ---
#-----------

package DBmaster;

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
use Mojo::Server::Prefork;
use Mojo::Util qw(dumper getopt);
use File::stat;

my $appname = 'dbmaster';
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
my $app = $server->build_app('DBmaster');
$app = $app->controller_class('DBmaster::Controller');

$app->secrets(['6d578e43ba88260e0375a1a35fd7954b']);

$app->static->paths(['@app_libdir@/public']);
$app->renderer->paths(['@app_libdir@/templs']);

$app->config(conffile => $conffile || '@app_confdir@/dbmaster.conf');
$app->config(pwfile => '@app_confdir@/dbmaster.pw');
$app->config(logfile => '@app_logdir@/dbmaster.log');
$app->config(loglevel => 'info');
$app->config(pidfile => '@app_rundir@/dbmaster.pid');
$app->config(crtfile => '@app_confdir@/dbmaster.crt');
$app->config(keyfile => '@app_confdir@/dbmaster.key');

$app->config(listenaddr4 => '0.0.0.0');
$app->config(listenaddr6 => '[::]');
$app->config(listenport => '8183');


$app->config(dbname => '@app_datadir@/pgmaster.db');
$app->config(dbhost => '');
$app->config(dblogin => '');
$app->config(dbpassword => '');
$app->config(dbengine => 'sqlite3');

$app->config(group => $group || '@app_group@');
$app->config(user => $user || '@app_user@');

if (-r $app->config('conffile')) {
    $app->log->debug("Load configuration from ".$app->config('conffile'));
    my $c = aConfig->new($app->config('conffile'));
    my $hash = $c->read;

    foreach my $key (keys %$hash) {
        $app->config($key => $hash->{$key});
    }
}

#---------------
#--- HELPERS ---
#---------------

$app->helper(
    db => sub {
        my $engine = 'SQLite' if $app->config('dbengine') =~ /sqlite/i;
        $engine = 'Pg' if $app->config('dbengine') =~ /postgres/i;
        state $db = aDBI->new(
            database => $app->config('dbname'),
            hostname => $app->config('dbhost'),
            username => $app->config('dblogin'),
            password => $app->config('dbpassword'),
            engine => $engine
        );
});

$app->helper(
    master => sub {
        state $user = aMaster->new($app->db); 
});

$app->helper('reply.not_found' => sub {
        my $c = shift; 
        return $c->redirect_to('/login') unless $c->session('username'); 
        $c->render(template => 'not_found.production');
});


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
$r->any('/logout')->over('auth')->to('controller#logout');

$r->any('/')->over('auth')->to('controller#hello' );
$r->any('/hello')->over('auth')->to('controller#hello');

$r->any('/agent/list')->over('auth')->to('controller#agent_list' );
$r->any('/agent/add/form')->over('auth')->to('controller#agent_add_form' );
$r->any('/agent/add/handler')->over('auth')->to('controller#agent_add_handler' );
$r->any('/agent/update/form')->over('auth')->to('controller#agent_update_form' );
$r->any('/agent/update/handler')->over('auth')->to('controller#agent_update_handler' );
$r->any('/agent/delete/form')->over('auth')->to('controller#agent_delete_form' );
$r->any('/agent/delete/handler')->over('auth')->to('controller#agent_delete_handler' );



#----------------
#--- LISTENER ---
#----------------

my $tls = '?';
$tls .= 'cert='.$app->config('crtfile');
$tls .= '&key='.$app->config('keyfile');

my $listen4;
if ($app->config('listenaddr4')) {
    $listen4 = "http://";
    $listen4 .= $app->config('listenaddr4').':'.$app->config('listenport');
    $listen4 .= $tls;
}

my $listen6;
if ($app->config('listenaddr6')) {
    $listen6 = "http://";
    $listen6 .= $app->config('listenaddr6').':'.$app->config('listenport');
    $listen6 .= $tls;
}

my @listen;
push @listen, $listen4 if $listen4;
push @listen, $listen6 if $listen6;

$server->listen(\@listen);
$server->heartbeat_interval(3);
$server->heartbeat_timeout(60);

$app->log(Mojo::Log->new( 
                path => $app->config('logfile'),
                level => $app->config('loglevel')
));

#--------------
#--- DAEMON ---
#--------------

unless ($nofork) {
    my $d = aDaemon->new;
    my $user = $app->config('user');
    my $group = $app->config('group');
    $d->fork;
    $app->log(Mojo::Log->new(
                path => $app->config('logfile'),
                level => $app->config('loglevel')
    ));
}

$server->pid_file($app->config('pidfile'));

#-----------
#--- LOG ---
#-----------

$app->hook(before_dispatch => sub {
        my $c = shift;

        my $remote_address = $c->tx->remote_address;
        my $method = $c->req->method;

        my $base = $c->req->url->base->to_string;
        my $path = $c->req->url->path->to_string;
        my $loglevel = $c->app->log->level;
        my $url = $c->req->url->to_abs->to_string;

        my $username  = $c->session('username') || 'undef';

        unless ($loglevel eq 'debug') {
            #$c->app->log->info("$remote_address $method $base$path $username");
            $c->app->log->info("$remote_address $method $url $username");
        }
        if ($loglevel eq 'debug') {
            $c->app->log->debug("$remote_address $method $url $username");
        }
});

#--------------
#--- SIGNAL ---
#--------------

# Set signal handler
local $SIG{HUP} = sub {
    $app->log->info('Catch HUP signal'); 
    $app->log(Mojo::Log->new(
                    path => $app->config('logfile'),
                    level => $app->config('loglevel')
    ));
};

my $sub = Mojo::IOLoop::Subprocess->new;
$sub->run(
    sub {
        my $subproc = shift;
        my $loop = Mojo::IOLoop->singleton;
        my $id = $loop->recurring(
            300 => sub {
            }
        );
        $loop->start unless $loop->is_running;
        1;
    },
    sub {
        my ($subprocess, $err, @results) = @_;
        $app->log->info('Exit subprocess');
        1;
    }
);

my $pid = $sub->pid;
$app->log->info("Subrocess $pid start ");

$server->on(
    finish => sub {
        my ($prefork, $graceful) = @_;
        $app->log->info("Subrocess $pid stop");
        kill('INT', $pid);
    }
);

$server->run;
#EOF
