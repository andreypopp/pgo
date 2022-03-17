-- This is just needed for re-creating the objects.
drop foreign table if exists ps;
drop foreign table if exists ps_unrestricted;
drop server if exists ps;
drop foreign data wrapper if exists ps_fdw;
drop function if exists ps_fdw_handler();
drop function if exists ps_fdw_validator(text[], oid);

-- Define ps_fdw_handler() and ps_fdw_validator() functions which are exposed
-- by the ps_fdw extension.
create function ps_fdw_handler()
  RETURNS fdw_handler
  as 'ps_fdw.so'
  language c strict
;

create function ps_fdw_validator(text[], oid)
  returns void
  as 'ps_fdw.so'
  language c strict
;

-- Define a datawrapper.
create foreign data wrapper ps_fdw
  handler ps_fdw_handler
  validator ps_fdw_validator
;

-- Define a foreign server.
create server ps foreign data wrapper ps_fdw;

-- Define a foreign table with the server.
create foreign table if not exists ps (
    pid int,
    command text,
    username text,
    time text
  )
  server ps
;

-- Another foreign table which have additional options.
create foreign table if not exists ps_unrestricted (
    pid int,
    command text,
    username text,
    time text
  )
  server ps
  options (show_command 'true')
;
