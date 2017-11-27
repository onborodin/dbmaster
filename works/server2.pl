#!/usr/local/bin/perl

package Dumper;

use strict;
use warnings;
use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;
}

1;

use strict;
use warnings;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Mojo::IOLoop::Subprocess;


sub timestamp {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $date = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon, $mday, $hour, $min, $sec);
    return $date;
}

my $server = Mojo::Server::Daemon->new;

$server->ioloop->recurring(1 => sub {

    my $loop = shift;

    my $sub = Mojo::IOLoop::Subprocess->new;

    $sub->run(
      sub {
        my $sub = shift;
        my $start = timestamp();
        sleep 3.5;
        return  $start . " " . timestamp() . ' subprocess 1';
      },

      sub {
        my ($sub, $err, @results) = @_;
        print "Subprocess error: $err\n" and return if $err;
        print "$results[0]\n";
      }
    );

    $sub->run(
        sub {
        my $sub = shift;
        my $start = timestamp();
        sleep 2;
        return  $start . " " . timestamp() . ' subprocess 2';
      },
      sub {
        my ($sub, $err, @results) = @_;
        print "Subprocess error: $err\n" and return if $err;
        print "$results[0]\n";
      }
    );

    $sub->ioloop->start unless $sub->ioloop->is_running;

    my $ua = Mojo::UserAgent->new;
    my $res = $ua->get('www.gnu.org')->result;
    print $res->dom->at('title')->text . "\n";
    print timestamp() . " Hi." . "\n";

});

#my $app = $server->build_app('Dumper');

$server->run;

#EOF
