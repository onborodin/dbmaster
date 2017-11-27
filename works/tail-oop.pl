#!/usr/bin/env perl

package Tail;

use strict;
use warnings;

sub new {
    my ($class, $file) = @_;
    my $self = {
        file => $file,
        pos => 0
    };
    bless $self, $class;
    return $self;
}

sub file {
    my ($self, $name) = @_;
    return $self->{'file'} unless $name;
    $self->{'file'} = $name;
}

sub pos {
    my ($self, $pos) = @_;
    return $self->{'pos'} unless $pos;
    $self->{'pos'} = $pos;
}


sub first {
    my $self = shift;
    open my $fh, '<', $self->file;
    seek $fh, -10, 2;
    readline $fh;
    my $res = '';
    while (my $line = readline $fh) {
        $res .= $line;
    }
    $self->pos(tell $fh);
    $res;
}

sub last {
    my $self = shift;
    open my $fh, '<', $self->file;
    seek $fh, $self->pos, 0;
    my $res = '';
    while (my $line = readline $fh) {
        $res .= $line;
    }
    $self->pos(tell $fh);
    $res;
}

1;

use strict;
use warnings;

my $t = Tail->new('/var/log/debug.log');
print $t->file . "\n";

print $t->first;
print $t->pos;

while (1) {
    print $t->last;
    sleep 1;
}
#EOF



