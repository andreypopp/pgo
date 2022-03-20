-- This is just needed for re-creating the objects.
drop foreign table if exists github_issues;
drop server if exists github;
drop foreign data wrapper if exists github_fdw;
drop function if exists github_fdw_handler();
drop function if exists github_fdw_validator(text[], oid);

create function github_fdw_handler()
  RETURNS fdw_handler
  as 'github_fdw.so'
  language c strict
;

create function github_fdw_validator(text[], oid)
  returns void
  as 'github_fdw.so'
  language c strict
;

create foreign data wrapper github_fdw
  handler github_fdw_handler
  validator github_fdw_validator
;

create server github
  foreign data wrapper github_fdw;

create foreign table if not exists esy_issues (data jsonb)
  server github
  options (kind 'issues', repo_owner 'esy', repo_name 'esy');
