# ps_fdw

This is an example FDW implemented using pgo.

It exposes `ps` (information about currently running processes on the system) as
a table. An option `show_command` (default `false`) is present to control
whether to disclose the command process was started with.
