# GitHub FDW

This FDW uses curl library to query GitHub API. See `github_fdw.sql` for needed
setup.

The only supported data is repository issues:

```
create foreign table if not exists esy_issues (data jsonb)
  server github
  options (kind 'issues', repo_owner 'esy', repo_name 'esy');
```

Note that the data is exposed as JSONB, the idea is that PostgreSQL's JSON
native support should be enough to bring this data into relational schema
easily.

Before querying GitHub FDW one should set the following configuration
parameters:

```
set github.username to '...';
set github.access_token to '...';
```
