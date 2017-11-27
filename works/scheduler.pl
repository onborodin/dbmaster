#!/usr/bin/env perl

use POSIX qw(tzset tzname strftime);
use Mojo::Util qw(dumper);

$ENV{TZ} = 'Europe/Moscow';
tzset;

sub expand {
    my ($def, $limit, $start) = @_;
    $limit = 100 unless defined $limit;
    $start = 1 unless defined $start;
    my @list = split ',', $def;
    my @out;
    my %n;
    foreach my $sub (@list) {
        if (my ($num) = $sub =~ m/^(\d+)$/ ) {
                next if $num < $start;
                next if $num > $limit;
                push @out, $num unless $n{$num};
                $n{$num} = 1;
        }
        elsif (my ($begin, $end) = $sub =~ /^(\d+)[-. ]+(\d+)$/) {
            foreach my $num ($begin..$end) {
                next if $num < $start;
                next if $num > $limit;
                push @out, $num unless $n{$num};
                $n{$num} = 1;
            }
        }
        elsif (my ($inc) = $sub =~ /^[*]\/(\d+)$/) {
            my $num = $start;
            while ($num <= $limit) {
                next if $num < $start;
                push @out, $num unless $n{$num};
                $num += $inc;
            }
        }
        elsif ($sub =~ /^[*]$/) {
            my $num = $start;
            my $inc = 1;
            while ($num <= $limit) {
                next if $num < $start;
                next if $num > $limit;
                push @out, $num unless $n{$num};
                $num += $inc;
            }
        }
    }
    @out = sort { $a <=> $b } @out;
    return \@out
}

sub compact {
    my $list = shift;
    my %n;
    my $out;
    foreach my $num (@{$list}) { $n{$num} = 1; }
    foreach my $num (sort { $a <=> $b } (keys %n)) {
        $out .= $num."-" if $n{$num+1} && not $n{$num-1};
        $out .= $num."," unless $n{$num+1};
    }
    $out =~ s/,$//;
    return $out;
}

sub match {
    my ($num, $list) = @_;
    foreach my $elem (@{$list}) {
        return 1 if $num == $elem;
    }
    return undef;
}

my $list = "*/3";
print (dumper (expand $list))."\n";
#my $expanded = expand($list);
#my $compacted = compact($expanded);
#print "$compacted\n";

exit;

### mdays, wdays, $hours, $mins
my $cronrec = "1-31 1-7 0-28 * 0-8,*/10,42-47,*/16";
my ($mdays, $wdays, $hours, $mins, $secs) = split '[ ;]', $cronrec;

print "mdays=".compact(expand $mdays, 31)."\n";
print "wdays=".compact(expand $wdays, 7)."\n";
print "hours=".compact(expand $hours, 23, 0)."\n";
print "mins=".compact(expand $mdays, 59, 0)."\n";
print "secs=".compact(expand $secs, 59, 0)."\n";

while (sleep 1) {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime(time);
    $mon++; # 1..12 - Jan..Dec
    $wday = 7 if $wday == 0; # 1..7 -- Mon..Sun
    $year += 1900;

    if (match($mday, expand ($mdays,31))
        && match($wday, expand ($wdays,7))
        && match($hour, expand ($hours, 23, 0))
        && match($min, expand ($mins, 59, 0))
        && match($sec, expand ($secs, 59, 0))) {
                print "match -- mday=$mday wday=$wday $hour:$min:$sec\n";
    }
#    ($sec,$min) = localtime(time);
#    sleep (59-$sec);
}



#EOF
