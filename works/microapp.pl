#!/usr/bin/env perl

#------------------
#--- CONTROLLER ---
#------------------

package MicroApp::Cont;

use utf8;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(quote b64_encode b64_decode md5_sum dumper url_escape);
use Mojo::JSON qw(encode_json decode_json);

sub hello {
    my $self = shift;
    $self->render(template => 'hello')
}

1;
#-----------
#--- APP ---
#-----------
package MicroApp;

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

use Mojo::Server::Prefork;
use Mojo::IOLoop::Subprocess;
use Mojo::Util qw(monkey_patch b64_encode b64_decode md5_sum getopt dumper);
use File::Basename;

my $server = Mojo::Server::Prefork->new;
my $appname = basename(__FILE__, ".pl");
my $workdir = dirname(__FILE__);

my $app = $server->build_app('MicroApp');

$app->config(
        libdir => "$workdir",
        pidfile => "$appname.pid",
        logfile => "$appname.log",
        mode => "production"
);

$app->max_request_size(1024*1024*1024);
$app->moniker($appname);
#$app->mode('production');
$app->secrets([ md5_sum(localtime(time)) ]);
#$app->log(Mojo::Log->new(path => $app->config('logfile')));

$app->static->paths->[0] = $app->config('libdir').'/public';
$app->renderer->paths->[0] = $app->config('libdir').'/templates';

my $r = $app->routes;
$r->any('/hello')->to('Cont#hello');

$server->listen(["http://0.0.0.0:3000"]);

$server->pid_file($app->config('pidfile'));

$server->heartbeat_interval(3);
$server->heartbeat_timeout(60);

$server->run;
#EOF
