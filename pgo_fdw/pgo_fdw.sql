drop foreign table if exists hello;
drop server if exists hello;
drop foreign data wrapper if exists pgo_fdw;
drop function if exists pgo_fdw_handler();
drop function if exists pgo_fdw_validator(text[], oid);

create function pgo_fdw_handler()
  RETURNS fdw_handler
  as 'pgo_fdw.so'
  language c strict
;

create function pgo_fdw_validator(text[], oid)
  returns void
  as 'pgo_fdw.so'
  language c strict
;

create foreign data wrapper pgo_fdw
  handler pgo_fdw_handler
  validator pgo_fdw_validator
;

create server hello foreign data wrapper pgo_fdw;

create foreign table if not exists hello (
    text text,
    int bigint,
    float double precision,
    bool bool,
    data jsonb
  )
  server hello
;
