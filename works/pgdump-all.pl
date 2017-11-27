#!/usr/bin/env perl

package PGu;

use Data::Dumper;
use DBI;
use strict;

sub new {
    my ($class, $pghost, $username, $password) = @_;
    my $self = { 
        pghost => $pghost,
        dsn => "dbi:Pg:dbname=postgres;host=$pghost",
        username => $username,
        password => $password,
    };
    bless $self, $class;
    return $self;
}

sub dsn { return shift->{dsn}; }
sub username { return shift->{username}; }
sub password { return shift->{password}; }

sub dbsize {

    my ($self, $dbname) = @_;
    my $db = DBI->connect($self->dsn, $self->username, $self->password) or return -1;

    my $query = "select pg_database_size('$dbname');";
    my $sth = $db->prepare($query);
    my $rows = $sth->execute or return -1;
    my $row = $sth->fetchrow_array;
    $sth->finish;
    $db->disconnect;
    my $dbsize = int($row/1024/1024);
    return $dbsize;
}

sub dblist {
    my $self = shift;
    my $db = DBI->connect($self->dsn, $self->username, $self->password) or return -1;

    my $query = "select datname from pg_stat_database;";
    my $sth = $db->prepare($query);
    my $rows = $sth->execute;

    my @dblist;
    while (my $row = $sth->fetchrow_hashref) {
        my $dbname = $row->{'datname'};
        push @dblist, $dbname;
    }
    $sth->finish;
    $db->disconnect;
    return \@dblist;
}
1;

use Data::Dumper;
use DBI;
use strict;


my @pghosts = ( 'r1-uk24.lazurit.us', 'r1-uk25.lazurit.us' );

foreach my $pghost (@pghosts) {

    my $username = 'postgres';
    my $password = 'password';

    my $pgu = PGu->new($pghost, $username, $password);

    my $dblist = $pgu->dblist;

#    print Dumper($dblist);

    do { print "$pghost: error list databases, exit\n"; next } if $dblist < 0;

    foreach my $dbname (sort @{$dblist}) {

        next if $dbname =~ m/template/;
        next if $dbname =~ m/postgres/;

        my $dbsize = $pgu->dbsize($dbname);
        my $dbdump = $dbname . '.sqlz';

        do { print "$pghost->$dbname: dump $dbdump exist\n"; next; } if -f $dbdump;
        print "$pghost->$dbname: to dump with dbsize=$dbsize\n";

        my $out = qx/PGPASSWORD=$password pg_dump -h $pghost -U $username -Fc -f $dbdump $dbname 2>&1/;
        my $retcode = $?;
        do { print "do error with err code=$retcode\n and message: $out"; unlink $dbdump; } if $retcode > 0;
    }
}
#EOF
