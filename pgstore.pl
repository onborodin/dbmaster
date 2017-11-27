#!@PERL@

1;

#------------
#--- AUTH ---
#------------

package PGstore::BasicAuth;

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

package PGstore::Daemon;

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

#-------------------
#--- CONTROLLER  ---
#-------------------

package PGstore::Controller;

use utf8;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(md5_sum dumper quote encode url_unescape);
use Mojo::JSON qw(encode_json decode_json false true);
use File::Basename;
use Filesys::Df;
use File::stat;
use POSIX;

sub renderFile {
    my $self = shift;
    my %args = @_;
    utf8::decode($args{filename}) if $args{filename} && !utf8::is_utf8($args{filename});
    utf8::decode($args{filepath}) if $args{filepath} && !utf8::is_utf8($args{filepath});

    my $filename = $args{filename};
    my $status = $args{status} || 200;
    my $content_disposition = $args{content_disposition}  || 'attachment';
    my $cleanup = $args{cleanup} // 0;

    # Content type based on format
    my $content_type;
    $content_type = $self->app->types->type( $args{format} ) if $args{format};
    $content_type ||= 'application/octet-stream';

    # Create asset
    my $asset;
    if ( my $filepath = $args{filepath} ) {
        unless ( -f $filepath && -r $filepath ) {
            $self->app->log->error("Cannot read file [$filepath]. error [$!]");
            return $self->rendered(404);
        }
        $filename ||= fileparse($filepath);
        $asset = Mojo::Asset::File->new( path => $filepath );
        $asset->cleanup($cleanup);
    } elsif ( $args{data} ) {
        $filename ||= $self->req->url->path->parts->[-1] || 'download';
        $asset = Mojo::Asset::Memory->new();
        $asset->add_chunk( $args{data} );
    } else {
        $self->app->log->error('You must provide "data" or "filepath" option');
        return;
    }
    # Set response headers
    my $headers = $self->res->content->headers();

    $filename = quote($filename); # quote the filename, per RFC 5987
    $filename = encode("UTF-8", $filename);

    $headers->add( 'Content-Type', $content_type . '; name=' . $filename );
    $headers->add( 'Content-Disposition', $content_disposition . '; filename=' . $filename );

    # Range, partially based on Mojolicious::Static
    if ( my $range = $self->req->headers->range ) {
        my $start = 0;
        my $size  = $asset->size;
        my $end   = $size - 1 >= 0 ? $size - 1 : 0;

        # Check range
        if ( $range =~ m/^bytes=(\d+)-(\d+)?/ && $1 <= $end ) {
            $start = $1;
            $end = $2 if defined $2 && $2 <= $end;

            $status = 206;
            $headers->add( 'Content-Length' => $end - $start + 1 );
            $headers->add( 'Content-Range'  => "bytes $start-$end/$size" );
        } else {
            # Not satisfiable
            return $self->rendered(416);
        }
        # Set range for asset
        $asset->start_range($start)->end_range($end);
    } else {
        $headers->add( 'Content-Length' => $asset->size );
    }
    # Stream content directly from file
    $self->res->content->asset($asset);
    return $self->rendered($status);
}

sub hello {
    my $self = shift;
    $self->render(json => { message => 'hello', success => true });
}

sub data_list {
    my $self = shift;

    my $datadir = $self->app->config("datadir");
    return $self->render(json => { datalist => undef, success => false }) unless -d $datadir;
    return $self->render(json => { datalist => undef, success => false }) unless -r $datadir;

    opendir(my $dh, $datadir);
    my @list;

    while (my $name = readdir($dh)) {
        next if ($name =~ m/^\./);
        my $datafile = "$datadir/$name";
        next if -d $datafile;
        next unless -r $datafile;

        my $st = stat($datafile);
        my $mtime = strftime("%Y-%m-%d %H:%M:%S %Z", localtime($st->mtime));
        push (@list, { name => $name, mtime => $mtime, size => $st->size });

    }
    closedir $dh;
    $self->render(
        json => { datalist => \@list, success => true }
    );
}

sub data_get {
    my $self = shift;

    my $dataname = $self->req->param('dataname');
    return $self->rendered(404) unless $dataname;

    $dataname = url_unescape($dataname);

    my $datadir = $self->app->config("datadir");

    my $file = "$datadir/$dataname";
    return $self->rendered(404) unless -r $file;
    return $self->rendered(404) unless -f $file;
    $self->renderFile(filepath => "$file");
}

sub data_put {
    my $self = shift;

    my $datadir = $self->app->config("datadir");

    return $self->render(json => { datalist => undef, success => false }) unless -d $datadir;
    return $self->render(json => { datalist => undef, success => false }) unless -w $datadir;
    return $self->render(json => { datalist => undef, success => false }) if $self->req->is_limit_exceeded;

    my @filenames;

    my $uploads = $self->req->uploads;

    foreach my $upload (@{$uploads}) {
        my $dataname = $upload->filename =~ s/^[ \.]+/_/gr;
        my $datasize = $upload->size;

        my $df = df("$datadir", 1);
        return $self->render(json => { success => false }) if $df->{bfree}+1 < $datasize;

        my $datafile = "$datadir/$dataname";
        $upload->move_to($datafile);

        my $st = stat($datafile);
        my $realsize = $st->size;
        do {
            unlink $dataname;
            next;
        } if $datasize != $realsize;
        push @filenames, { name => $dataname, size => $datasize, realsize => $realsize, realname => $datafile };
    }

    $self->render(json => { datalist => \@filenames, success => true });
}

sub data_free {
    my $self = shift;
    my $datadir = $self->app->config('datadir');
    return $self->render(json => { success => false }) unless -d $datadir;
    return $self->render(json => { success => false }) unless -r $datadir;
    my $df = df($datadir, 1);
    $self->render(json => { total => $df->{blocks}, free => $df->{bfree}, success => true });

}

sub data_delete {
    my $self = shift;

    my $datadir = $self->app->config('datadir');
    my $dataname = $self->req->param('dataname');

    return $self->render(json => { dataname => $dataname, success => false }) unless $dataname;
    return $self->render(json => { dataname => $dataname, success => false }) unless -d $datadir;
    return $self->render(json => { dataname => $dataname, success => false }) unless -w $datadir;

    my $datafile = "$datadir/$dataname";
    return $self->render(json => { dataname => $dataname, success => true, size => 0}) unless -f $datafile;

    my $st = stat($datafile);
    my $datasize = $st->size;

    return $self->render(json => { dataname => $dataname, success => true, size => $datasize }) if unlink($datafile);
    $self->render(json => { dataname => $dataname, success => false, size => $datasize });
}

1;

#-----------
#--- APP ---
#-----------

package PGstore;

use strict;
use warnings;
use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;
}

1;

#-------------
#------------
#--- MAIN ---
#------------
#-------------

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
my $app = $server->build_app('PGstore');
$app = $app->controller_class('PGstore::Controller');

$app->secrets(['6d578e43ba88260e0375a1a35fd7954b']);
$app->static->paths(['@APP_LIBDIR@/public']);
$app->renderer->paths(['@APP_LIBDIR@/templs']);

$app->config(conffile => $conffile || '@APP_CONFDIR@/pgstore.conf');
$app->config(pwdfile => '@APP_CONFDIR@/pgstore.pw');
$app->config(logfile => '@APP_LOGDIR@/pgstore.log');
$app->config(loglevel => 'info');
$app->config(pidfile => '@APP_RUNDIR@/pgstore.pid');
$app->config(crtfile => '@APP_CONFDIR@/pgstore.crt');
$app->config(keyfile => '@APP_CONFDIR@/pgstore.key');

$app->config(user => $user || '@APP_USER@');
$app->config(group => $group || '@APP_GROUP@');

$app->config(listenaddr4 => '0.0.0.0');
$app->config(listenaddr6 => '[::]');
$app->config(listenport => '3001');

$app->config(datadir => '@PGSTORE_DATADIR@');


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
        my $a = PGstore::BasicAuth->new($pwdfile);
        $log->info("Try auth user ". $a->username($authstr));
        $a->auth($authstr);

    }
);

$r->any('/hello')       ->to('Controller#hello');

$r->any('/data/list')   ->over('auth') ->to('Controller#data_list');
$r->any('/data/get')    ->over('auth') ->to('Controller#data_get');
$r->any('/data/put')    ->over('auth') ->to('Controller#data_put');
$r->any('/data/free')   ->over('auth') ->to('Controller#data_free');
$r->any('/data/delete') ->over('auth') ->to('Controller#data_delete');

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
    my $d = PGstore::Daemon->new;
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
