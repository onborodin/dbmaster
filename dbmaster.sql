

drop database pgdumper;
create database pgdumper;

\c pgdumper
create table agent (
    id integer unique,
    hostname text unique,
    username text,
    password text
);


create table db (
    agentid integer,
    name text,
    size bigint,
    owner text,
    numbackends integer,
    type text
);

insert into agent values(1, 'thx.unix7.org', 'master', 'password');
insert into agent values(2, 'pgdb-msk.lazurit.us', 'master', 'password');
insert into agent values(3, 'pgdb-ost.lazurit.us', 'master', 'password');

create table store (
    id integer unique,
    hostname text unique,
    username text,
    password text,
    total bigint,
    free bigint
);

insert into store values(1, 'thx.unix7.org', 'master', 'password', 0, 0);
insert into store values(2, 'pgdb-msk.lazurit.us', 'master', 'password', 0, 0);
insert into store values(3, 'pgdb-ost.lazurit.us', 'master', 'password', 0, 0);

create table data (
    storeid integer,
    name text,
    dbname text,
    stamp timestamptz,
    datetime timestamp,
    tz text,
    source text,
    size bigint,
    mtime timestamptz,
    type text
);

create table schedule (
    id integer,
    type text,
    sourceid integer,
    destid integer,
    subject text,
    wday text,
    mday text,
    hour text,
    min text
);

create table job (
    id integer,
    begin timestamptz,
    stop timestamptz,
    author text,
    type text,
    sourceid integer,
    destid integer,
    status text,
    error  text,
    message text,
    magic text
)

