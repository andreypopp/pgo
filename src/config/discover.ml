module C = Configurator.V1

module Pg_config = struct
  type t = {
    includedir : string;
    includedir_server : string;
    pkgincludedir : string;
    libdir : string;
    pkglibdir : string;
  }

  let query c =
    let lines =
      C.Process.run_capture_exn c "pg_config"
        [
          "--includedir";
          "--includedir-server";
          "--pkgincludedir";
          "--libdir";
          "--pkglibdir";
        ]
      |> String.split_on_char '\n'
    in
    match lines with
    | [ includedir; includedir_server; pkgincludedir; libdir; pkglibdir; "" ] ->
      { includedir; includedir_server; pkgincludedir; libdir; pkglibdir }
    | lines ->
      C.die "unable to parse output from pg_config:\n%s"
        (String.concat "\n" lines)
end

let () =
  let line = Printf.sprintf in
  C.main ~name:"discover" (fun c ->
      let cfg = Pg_config.query c in
      C.Flags.write_lines "include-flags.lines"
        [ line "-I%s" cfg.includedir_server ];
      C.Flags.write_sexp "include-flags.sexp"
        [ line "-I%s" cfg.includedir_server ];
      C.Flags.write_lines "archives.lines"
        [ line "%s/libpgport.a" cfg.pkglibdir ];
      C.Flags.write_sexp "cflags.sexp"
        [
          "-Werror=implicit-function-declaration";
          line "-I%s" cfg.includedir_server;
          line "-fPIC";
        ])
