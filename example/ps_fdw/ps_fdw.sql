drop foreign table if exists ps;
drop foreign table if exists ps_unrestricted;
drop server if exists ps;
drop foreign data wrapper if exists ps_fdw;
drop function if exists ps_fdw_handler();
drop function if exists ps_fdw_validator0(text[], oid);

create function ps_fdw_handler()
  RETURNS fdw_handler
  as 'ps_fdw.so'
  language c strict
;

create function ps_fdw_validator0(text[], oid)
  returns void
  as 'ps_fdw.so'
  language c strict
;

create foreign data wrapper ps_fdw
  handler ps_fdw_handler
  validator ps_fdw_validator0
;

create server ps foreign data wrapper ps_fdw;

create foreign table if not exists ps (
    pid int,
    command text,
    username text,
    time text
  )
  server ps
;

create foreign table if not exists ps_unrestricted (
    pid int,
    command text,
    username text,
    time text
  )
  server ps
  options (show_command 'true')
;
