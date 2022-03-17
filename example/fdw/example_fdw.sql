drop foreign table if exists process;
drop server if exists hello;
drop foreign data wrapper if exists example_fdw;
drop function if exists example_fdw_handler();
drop function if exists example_fdw_validator0(text[], oid);

create function example_fdw_handler()
  RETURNS fdw_handler
  as 'example_fdw.so'
  language c strict
;

create function example_fdw_validator0(text[], oid)
  returns void
  as 'example_fdw.so'
  language c strict
;

create foreign data wrapper example_fdw
  handler example_fdw_handler
  validator example_fdw_validator0
;

create server hello foreign data wrapper example_fdw;

create foreign table if not exists process (
    pid int,
    command text,
    "user" text,
    time text
  )
  server hello
  options (city 'St.Petersburg')
;
