#!perl

use POSIX qw(tzset tzname strftime);
use Mojo::Util qw(dumper);

#$ENV{TZ} = 'America/Los_Angeles';
$ENV{TZ} = 'Europe/Moscow';
tzset;

($std, $dst) =  tzname();
print $std, " ",$dst."\n";

sub timestamp {
    return strftime("%Y%m%d-%H%M%S-%Z", localtime(time));
}

sub timestampUTC {
    return strftime("%Y%m%d-%H%M%S-UTC", gmtime(time));
}

use Socket;
use Sys::Hostname;
my $host = hostname();

my $timestamp = timestamp;
print "postgres--$timestamp--$host\n";
#print timestampUTC."\n";

#$timestamp  =~ /([01-9]+)/;

#print dumper \@time;

#print strftime("%Y%m%d-%H%M%S%Z", localtime(time))."\n";

#use POSIX;
#print strftime("%Z", localtime()), "\n";
#EOF
