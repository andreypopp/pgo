# pgo

**EXPERIMENTAL AND INCOMPLETE**

Build [PostgreSQL][] extensions in [OCaml][].

## Overview

- The project uses [ctypes][] with C stubs generation to interface with
  PostgreSQL/C API (both to use PostgreSQL/C API and to expose OCaml functions
  to PostgreSQL).

- Library `pgo.api` provide bindings (type definitions and functions bindings)
  to PostgreSQL/C API.

- Library `pgo.fdw` sketches a harness for implementing [FDW][] with OCaml.

- Library `example/fdw` implements an example [FDW][] which exposes a single
  table.

## Development

1. Make sure you have opam and PostgreSQL installed.

2. Initialize opam switch:

   ```
   make init
   ```

3. Build the project:

   ```
   make build
   ```

4. Initialize the test database:

   ```
   make test-db
   ```

5. Run `psql` shell within the test database with the example extension loaded:

   ```
   make psql
   ```

[FDW]: https://wiki.postgresql.org/wiki/Foreign_data_wrappers
[OCaml]: https://ocaml.org
[PostgreSQL]: https://www.postgresql.org
[ctypes]: https://github.com/ocamllabs/ocaml-ctypes
