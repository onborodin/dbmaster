#!/usr/local/bin/perl

use Mojo::IOLoop::Subprocess;

my $sub = Mojo::IOLoop::Subprocess->new;

$sub->run(
  sub {
    my $sub = shift;
    sleep 10;
    return 'love', 'Mojolicious';
  },
  sub {
    my ($sub, $err, @results) = @_;
    print "Subprocess error: $err\n" and return if $err;
    print "10: I $results[0] $results[1]!\n";
  }
);

$sub->run(
  sub {
    my $sub = shift;
    sleep 1;
    return 'love', 'Mojolicious';
  },
  sub {
    my ($sub, $err, @results) = @_;
    print "Subprocess error: $err\n" and return if $err;
    print "5: I $results[0] $results[1]!\n";
  }
);

#my $sub = Mojo::IOLoop::Subprocess->new;
print "Start subprocess\n";


$sub->ioloop->start unless $sub->ioloop->is_running;

#EOF

