drop function if exists func_add(integer, integer);
create function func_add(integer, integer) returns integer
     AS 'func.so', 'func_add'
     language c strict;
