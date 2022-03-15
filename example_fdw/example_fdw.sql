drop foreign table if exists hello;
drop server if exists hello;
drop foreign data wrapper if exists example_fdw;
drop function if exists example_fdw_handler();
drop function if exists example_fdw_validator(text[], oid);

create function example_fdw_handler()
  RETURNS fdw_handler
  as 'example_fdw.so'
  language c strict
;

create function example_fdw_validator(text[], oid)
  returns void
  as 'example_fdw.so'
  language c strict
;

create foreign data wrapper example_fdw
  handler example_fdw_handler
  validator example_fdw_validator
;

create server hello foreign data wrapper example_fdw;

create foreign table if not exists hello (
    text text,
    int bigint,
    float double precision,
    bool bool,
    data jsonb
  )
  server hello
;