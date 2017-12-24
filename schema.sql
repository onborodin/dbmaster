
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
    owner text
);

create table store (
    id integer unique,
    name text unique,
    login text,
    password text
);

create table data (
    store_id integer,
    name text,
    size bigint,
    mtime text,
    type text
);

create table schedule (
    id integer,
    type text,
    source_id integer,
    dest_id integer,
    subject text,
    wday text,
    mday text,
    hour text,
    min text
);

create table job (
    id integer,
    begin text,
    stop text,
    author text,
    type text,
    source_id integer,
    dest_id integer,
    status text,
    error  text,
    message text,
    magic text
)

