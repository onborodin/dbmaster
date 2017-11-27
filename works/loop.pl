#!/usr/local/bin/perl

use Mojo::IOLoop;

my $loop = Mojo::IOLoop->singleton;

my $id1 = $loop->recurring(1 => sub {
  my $loop = shift;
    print "Hi 1!\n";
});

my $id3 = $loop->recurring(3 => sub {
  my $loop = shift;
    print "   Hi 3!\n";
});

print "Start loop with $id1 and $id3\n";

$loop->start unless $loop->is_running;

#EOF
