#!/usr/local/bin/perl

use strict;
use warnings;
use Mojo::Util qw(dumper);


my $l = 'mail--20171012-135722-EET--think.unix7.org.sqlz';

sub parceLabel {
    my $label = shift;
    return undef unless $label;

    $label =~ s/.sqlz$//;

    my ($dbname, $Y, $M, $D, $h, $m, $s, $tz, $host) = 
        $label =~ /([a-z0-9]{1,64})--([0-9]{4})([0-9]{2})([0-9]{2})-([0-9]{2})([0-9]{2})([0-9]{2})-([A-Z]{2,3})--([a-zA-Z0-9\.]{1,64})/g;

    my %data;
    $data{'dbname'} = $dbname;
    $data{'timestamp'} = "$Y-$M-$D $h:$m:$s $tz";
    $data{'source'} = $host;
    return \%data;
}


print dumper(parceLabel $l);
#EOF




