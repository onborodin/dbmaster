#!/usr/bin/env perl

use strict;
use warnings;
use File::stat;

my $filename = "/var/log/debug.log";
#my $stat = stat($filename);
#my $size = $stat->size;

#open(my $fh, "<", $filename);
#seek($fh, 0, 2);

#my $num = 1;
#while ($fh) {
#    my $data = '';
#    while (!eof($fh)) {
#        $data .= $num. " -- ";
#        $data .= readline $fh;
#        $num++;
#    }
#    print $data;
#    seek($fh, 0, 1);
#    sleep(1);
#}
#EOF


open(my $fh, "<", $filename);

seek($fh, -1000, 2);
my $num = 1;
readline $fh;

my $data = '';
while (!eof($fh)) {
        $data .= $num. " -- ";
        $data .= readline $fh;
        $num++;
}
print $data;

while ($fh) {
    my $data = '';
    while (!eof($fh)) {
        $data .= $num. " -- ";
        $data .= readline $fh;
        $num++;
    }
    print $data;
    seek($fh, 0, 1);
    sleep(1);
}
#EOF


