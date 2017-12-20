

drop database dbmaster;
create database dbmaster;

\c dbmaster
create table agent (
    id integer unique,
    name text unique,
    login text,
    password text
);


create table db (
    agent_id integer,
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
    name text unique,
    login text,
    password text,
    total bigint,
    free bigint

);

insert into store values(1, 'thx.unix7.org', 'master', 'password', 0, 0);
insert into store values(2, 'pgdb-msk.lazurit.us', 'master', 'password', 0, 0);
insert into store values(3, 'pgdb-ost.lazurit.us', 'master', 'password', 0, 0);

create table data (
    store_id integer,
    name text,
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
    source_id integer,
    dest_id integer,
    status text,
    error  text,
    message text,
    magic text
)

