#!/usr/bin/env perl

#-------------------
#--- CONTROLLER  ---
#-------------------

package PGstore::Controller;

use utf8;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(md5_sum dumper quote encode url_unescape);
use Mojo::JSON qw(encode_json decode_json);
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
    $self->render(json => { message => "hello", result => "success" });
}

sub confDump {
    my $self = shift;
    $self->render(json => { config => $self->app->config, result => "success" });
}

sub dataList {
    my $self = shift;
    my $datadir = $self->app->config("datadir");

    return $self->render(json => { datalist => undef, result => 'mistake' }) unless -d $datadir;
    return $self->render(json => { datalist => undef, result => 'mistake' }) unless -r $datadir;

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
    my $df = df("/$datadir", 1);
    $self->render(
        json => { datalist => \@list, 
                  total => $df->{blocks}, 
                  free => $df->{bfree},
                  result => 'success' 
    });
}

sub dataGet {
    my $self = shift;
    my $dataname = $self->req->param('dataname');
    return $self->rendered(404) unless $dataname;

    $dataname = url_unescape($dataname);

    $self->app->log->debug("Get data $dataname");

    my $datadir = $self->app->config("datadir");
    my $file = "/$datadir/$dataname";
    return $self->rendered(404) unless -r $file;
    return $self->rendered(404) unless -f $file;
    $self->app->log->debug(" Store get file $file");
    $self->renderFile(filepath => "$file");
}

sub dataPut {
    my $self = shift;
    my $datadir = $self->app->config("datadir");

    return $self->render(
       json => { datalist => undef,
                 result => 'mistake',
                 message => "Datadir not exist" }) 
       unless -d $datadir;
    return $self->render(
        json => { datalist => undef,
                   result => 'mistake',
                   message => "Datadir not writable" }) 
        unless -w $datadir;

    return $self->rendered(406) if $self->req->is_limit_exceeded;

    my @filenames;
    my $uploads = $self->req->uploads;

    foreach my $upload (@{$uploads}) {
        my $dataname = $upload->filename =~ s/^[ \.]+/_/gr;
        my $datasize = $upload->size;
        my $df = df("/$datadir", 1);
        return $self->rendered(406) if $df->{bfree}+1024 < $datasize;

        my $datafile = "/$datadir/$dataname";

        $upload->move_to($datafile);

        # Check real file size
        my $st = stat($datafile);
        my $realsize = $st->size;
        $self->app->log->info("Dataset $dataname size $datasize was uploaded to $datafile with size $realsize");
        do {
            unlink $dataname;
            $self->app->log->info("Error: Dataset $dataname was deleted since datafile size not equal HTTP requested size");
            next;
        } if $datasize != $realsize;
        push @filenames, { name => $dataname, size => $datasize, realsize => $realsize, realname => $datafile };
    }
    my $df = df("/$datadir", 1);
    $self->render(
            json => { datalist => \@filenames , 
                        total => $df->{blocks}, 
                        free => $df->{bfree}, 
                        result => "success" 
    });
}

sub dataFree {
    my $self = shift;
    my $datadir = $self->app->config("datadir");
    return $self->render(
            json => { total => 0, 
                        free => 0, 
                        result => 'mistake', 
                        message => 'Datadir not exist' 
    }) unless -d $datadir;
    return $self->render(
            json => { total => 0, 
                        free => 0, 
                        result => 'mistake', 
                        message => 'Connot read datadir' 
    }) unless -r $datadir;
    my $df = df("/$datadir", 1);
    $self->render(
            json => { total => $df->{blocks}, 
                        free => $df->{bfree}, 
                        result => 'success' 
    });
}

sub dataDelete {
    my $self = shift;
    my $datadir = "/".$self->app->config("datadir");
    my $dataname = $self->req->param('dataname');
    $self->app->log->info("Try delete $dataname");

    return $self->render(
        json => { dataname => $dataname, result => 'mistake' 
    }) unless $dataname;
    return $self->render(
        json => { dataname => $dataname, result => 'mistake', message => 'Datadir not exist'
    }) unless -d $datadir;
    return $self->render(
        json => { dataname => $dataname, result => 'mistake', message => 'Cannot read datadir'
    }) unless -w $datadir;

    my $datafile = "$datadir/$dataname";
    return $self->render(
        json => { dataname => $dataname, result => 'success', size => -1, message => 'The dataset not exist' 
    }) unless -f $datafile;

    my $st = stat($datafile);
    my $datasize = $st->size;

    my $df = df("/$datadir", 1);

    return $self->render(
        json => { dataname => $dataname, result => 'success', total => $df->{blocks}, free => $df->{bfree}, size => $datasize
    }) if unlink($datafile);

    $self->render(
        json => { dataname => $dataname, result => 'mistake', total => $df->{blocks}, free => $df->{bfree}, size => $datasize });
}

1;

#-----------
#--- APP ---
#-----------

package PGstore;

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
use Mojo::Util qw(md5_sum b64_decode getopt dumper);
use Sys::Hostname qw(hostname);
use File::Basename qw(basename dirname);
use Apache::Htpasswd;
use Cwd qw(getcwd abs_path);
use EV;

my $appfile = abs_path(__FILE__);
my $appname = basename($appfile, ".pl");
$0 = $appfile;

getopt
    'h|help' => \my $help,
    '4|ipv4listen=s' => \my $ipv4listen,
    '6|ipv6listen=s' => \my $ipv6listen,
    'c|config=s' => \my $conffile,
    'p|pwdfile=s' => \my $pwdfile,
    'd|datadir=s' => \my $datadir,
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
    -d | --datadir=path   Path to application files 
    -l | --logfile=path   Path to log file
    -i | --pidfile=path   Path to process ID file
    -v | --verbose=level  Verbose level: debug, info, warn, error, fatal
    -u | --user=user      System owner of process
    -g | --group=group    System group 
    -f | --nofork         Dont fork process, for debugging

All path option override option from configuration file

    )."\n";
    exit 0;
}


my $server = Mojo::Server::Prefork->new;
my $app = $server->build_app('PGstore');
$app = $app->controller_class('PGstore::Controller');

$app->config(
    hostname => hostname,
    datadir => $datadir || "@PGSTORE_DATADIR@",
    listenIPv4 => $ipv4listen || "0.0.0.0",
    listenIPv6 => $ipv6listen || "[::]",
    listenPort => "3002",
    pghost => "127.0.0.1",
    pguser => "postgres",
    pgpasswd => "password",
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
    timezone => 'Europe/Moscow',
);

$conffile = $app->config('conffile');
do {
    $app->log->debug("Load configuration from $conffile ");
    my $config = $app->plugin( 'JSONConfig', { file => $conffile } );
} if -r $conffile;

$ENV{TZ} = $app->config('timezone');
tzset;

my $tlscert = $app->config('tlscert');
my $tlskey = $app->config('tlskey');
$datadir = $app->config('datadir');
my $rundir = dirname ($app->config('pidfile'));
my $logdir = dirname ($app->config('logfile'));
$pwdfile = $app->config('pwdfile');

do { print "Cannot write to data direcory $datadir\n"; exit 1; } unless -w $datadir;
do { print "Cannot write to run direcory $rundir\n"; exit 1; } unless -w $rundir;
do { print "Cannot write to log direcory $logdir\n"; exit 1; } unless -w $logdir;

do { print "Cannot read TLS certificate $tlscert\n"; exit 1; } unless -r $tlscert;
do { print "Cannot read TLS key $tlskey\n"; exit 1; } unless -r $tlskey;
do { print "Cannot read password file $pwdfile\n"; exit 1; } unless -r $pwdfile;

#-----------------------------
#--- check system accounts ---
#-----------------------------

my $appUser = $app->config('appuser');
my $appGroup = $app->config('appgroup');

my $appUID = getpwnam($appUser);
my $appGID = getgrnam($appGroup);

do { print "System user $appUser not exist.\n"; exit 1; } unless $appUID;
do { print "System group $appGroup not exist.\n"; exit 1; } unless $appGID;


$ENV{MOJO_TMPDIR} = $app->config("datadir");

$app->max_request_size($app->config("maxrequestsize"));
$app->moniker($appname);
$app->secrets([ md5_sum(localtime(time)) ]);

#$app->helper(
#    model => sub {
#        state $model = PGstore::Model->new($app);
#    }
#);

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
        $c->app->log->debug("Password file $passwdFile");
        do {
            $c->app->log->error("Cannot read password file '$passwdFile'");
            return undef;
        } unless -r $passwdFile;

        my $result = undef;
        eval {
            my $ht = Apache::Htpasswd->new( { passwdFile => $passwdFile, ReadOnly => 1 } );
            $result = $ht->htCheckPassword($username, $password);
        };
        do { $c->app->log->debug("Auth module error: $@"); return undef; } if $@;

        return 1 if $result;
        $c->app->log->info("Bad auth from " . $c->tx->remote_address);
        return undef;
    }
);

$r->any('/hello')->to('Controller#hello');

$r->any('/data/list')->over('auth')->to('Controller#dataList');
$r->any('/data/get')->over('auth')->to('Controller#dataGet');
$r->any('/data/put')->over('auth')->to('Controller#dataPut');
$r->any('/data/free')->over('auth')->to('Controller#dataFree');
$r->any('/data/delete')->over('auth')->to('Controller#dataDelete');

$r->any('/conf/dump')->over('auth')->to('Controller#confDump');

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
        chdir($datadir);
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
