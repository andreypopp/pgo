(lang dune 2.9)

(name pgo)

(generate_opam_files true)

(package
 (name pgo)
 (synopsis "Build PostgreSQL extensions in OCaml")
 (depends dune dune-action-plugin dune-configurator base stdio ctypes)
 (maintainers Andrey Popp <me@andreypopp.com>)
 (authors Andrey Popp <me@andreypopp.com>)
 (homepage https://github.com/andreypopp/pgo)
 (bug_reports https://github.com/andreypopp/pgo)
 (license MIT)
 )

(package
 (name pgo_example)
 (synopsis "Example of pgo")
 (depends dune ctypes pgo ocurl)
 (maintainers Andrey Popp <me@andreypopp.com>)
 (authors Andrey Popp <me@andreypopp.com>)
 (homepage https://github.com/andreypopp/pgo)
 (bug_reports https://github.com/andreypopp/pgo)
 (license MIT)
 )
