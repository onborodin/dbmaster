#!@PERL@


#------------
#--- CRON ---
#------------

package aCron;

use strict;
use warnings;

sub new {
    my ($class, $app) = @_;
    my $self = {
        app => $app
    };
    bless $self, $class;
    return $self;
}

sub ping {
    my $self = shift;
    "Pong!";
}

sub app {
    my $self = shift;
    $self->{app};
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

package DBmaster::DB;

use strict;
use warnings;
use DBI;

sub new {
    my ($class, %args) = @_;
    my $self = {
        host => $args{host},
        login => $args{login},
        password => $args{password},
        database => $args{database},
        engine => 'Pg',
        error => ''
    };
    bless $self, $class;
    return $self;
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

sub host {
    my ($self, $host) = @_; 
    return $self->{host} unless $host;
    $self->{host} = $host;
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
                ';host='.$self->host;
    my $dbi;
    eval {
        $dbi = DBI->connect($dsn, $self->login, $self->password, { 
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

sub exec1 {
    my ($self, $query) = @_;
    return undef unless $query;

    my $dsn = 'dbi:'.$self->engine.
                ':dbname='.$self->database.
                ';host='.$self->host;
    my $dbi;
    eval {
        $dbi = DBI->connect($dsn, $self->login, $self->password, { 
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
                ';host='.$self->host;
    my $dbi;
    eval {
        $dbi = DBI->connect($dsn, $self->login, $self->password, { 
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


#------------------
#--- CONTROLLER ---
#------------------

package DBmaster::Controller;

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


1;

#-----------
#--- APP ---
#-----------
package DBmaster;

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
$app->static->paths(['@APP_LIBDIR@/public']);
$app->renderer->paths(['@APP_LIBDIR@/templs']);

$app->config(conffile => $conffile || '@APP_CONFDIR@/dbmaster.conf');
$app->config(pwdfile => '@APP_CONFDIR@/dbmaster.pw');
$app->config(logfile => '@APP_LOGDIR@/dbmaster.log');
$app->config(loglevel => 'info');
$app->config(pidfile => '@APP_RUNDIR@/dbmaster.pid');
$app->config(crtfile => '@APP_CONFDIR@/dbmaster.crt');
$app->config(keyfile => '@APP_CONFDIR@/dbmaster.key');

$app->config(user => $user || '@APP_USER@');
$app->config(group => $group || '@APP_GROUP@');

$app->config(listenaddr4 => '0.0.0.0');
#$app->config(listenaddr6 => '[::]');
$app->config(listenport => '3003');

$app->config(tmpdir => '/tmp');
$app->config(timezone => 'Europe/Moscow');


$app->config(dbhost => '127.0.0.1');
$app->config(dblogin => 'postgres');
$app->config(dbpwd => 'password');
$app->config(dbname => 'pgdumper');

if (-r $app->config('conffile')) {
    $app->log->debug("Load configuration from ".$app->config('conffile'));
    $app->plugin('JSONConfig', { file => $app->config('conffile') });
}

#$app->max_request_size($app->config("maxrequestsize"));

#----------------
#--- TIMEZONE ---
#----------------
$ENV{TZ} = $app->config('timezone');
tzset;

#---------------
#--- HELPERS ---
#---------------

$app->helper('reply.not_found' => sub {
        my $c = shift; 
        return $c->redirect_to('/login') unless $c->session('username'); 
        $c->render(template => 'not_found.production');
});

$app->helper(
    dbi => sub {
        my $db = aDBI->new(
                        host => $app->config("dbhost"),
                        login => $app->config("dblogin"),
                        password => $app->config("dbpassword"),
                        database => $app->config("dbname"),
        );
    }
);

$app->helper(
    cron => sub {
        state $cron = aCron->new($app);
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
$r->any('/logout')->to('controller#logout');
$r->any('/hello')->over('auth')->to('controller#hello');

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
    my $d = DBmaster::Daemon->new;
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

my $sub = Mojo::IOLoop::Subprocess->new;
$sub->run(
    sub {
        my $subproc = shift;
        my $loop = Mojo::IOLoop->singleton;
        my $id = $loop->recurring(
            10 => sub {
                my $cron = $app->cron;
                my $m = $app->model;
                my $log = $app->log;

                my $ct = $m->curr_time;

                my $c_mday = $ct->{mday};
                my $c_wday = $ct->{wday};
                my $c_hour = $ct->{hour};
                my $c_min = $ct->{min};
                my $c_sec = $ct->{sec};

                foreach my $rec (@{$m->schedule_list}) {

                    my $id = $rec->{id};
                    my $dest_id = $rec->{destid};
                    my $source_id = $rec->{sourceid};

                    my $list_mday  = $cron->period_expand($rec->{mday}, 31, 1);
                    my $list_wday  = $cron->period_expand($rec->{wday}, 7, 1);
                    my $list_hour  = $cron->period_expand($rec->{hour}, 23, 0);
                    my $list_min  = $cron->period_expand($rec->{min}, 59, 0);

                    my $min = $rec->{min};

                    my $type  = $rec->{type};
                    my $subject = $rec->{subject};

                    if ($cron->period_match($c_min, $list_min)
                        && $cron->period_match($c_hour, $list_hour)
                        && $cron->period_match($c_wday, $list_wday)
                        && $cron->period_match($c_mday, $list_mday)) {

#                        $log->debug("--- Match type=$type subject=$subject id=$id :  $min == $c_min ");
#
#                        if ($m->agent_alive($source_id)) {
#                                my $hostname = $m->agent_hostname($source_id);
#                                $log->debug("--- Agent $hostname is alive!");
#                        }
                    }

                }
                my $res = $app->cron->ping;
                $app->log->info($res);
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
