
create table host (
    hostid int,
    hostname text,
    hostlogin text,
    hostpassword text,
    workdir text
    dbname text,
    dblogin text,
    dbpassword text
);

create table db (
    dbid int,
    hostid int,
    dbname text,
    dblogin text,
    dbpassword text
);

create table recjob {
    recjobid int,
    cron text,
    dbid int,
    timestamp text,
    status text
}

create table job {
    jobid int,
    recjobid int,
    timestart text,
    timeend text,
    status text
    log text,
}

create table dump {
    dumpid int,
    dbid int,
    jobid int,
    dumplabel text,
    status text
}


