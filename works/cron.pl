#!/usr/local/bin/perl

use strict;
use warnings;
use Time::Crontab;

sub timestamp {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $date = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon, $mday, $hour, $min, $sec);
    return $date;
}

print timestamp() . "\n";

my $cron = Time::Crontab->new('*/3 * * * *');


while(1) {
    if ( $cron->match(time()) ) {
        print timestamp() . "\n";
        sleep 1;
    }
}
#EOF

