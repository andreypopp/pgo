let template =
  {ocaml|
let c_prelude =
  {c|
#include "pgo_api.h"
#pragma GCC diagnostic ignored "-Wunused-variable"
  |c}

let run () =
  let pg_bindings = (module MODULE.Def : Pgtypes.BINDINGS) in
  let bindings = Pgtypes.to_ctypes pg_bindings in
  Out_channel.with_file "internal.ml" ~f:(fun oc ->
      Cstubs_inverted.write_ml
        (Caml.Format.formatter_of_out_channel oc)
        ~prefix:"NAME" bindings);
  Out_channel.with_file "internal.c" ~f:(fun oc ->
      Caml.Format.fprintf
        (Caml.Format.formatter_of_out_channel oc)
        "%s\n%a" c_prelude
        (Cstubs_inverted.write_c ~prefix:"NAME")
        bindings);
  Out_channel.with_file "internal.h" ~f:(fun oc ->
      Cstubs_inverted.write_c_header
        (Caml.Format.formatter_of_out_channel oc)
        ~prefix:"NAME" bindings);
  Out_channel.with_file "NAME_driver.c" ~f:(fun oc ->
      let fmt = Caml.Format.formatter_of_out_channel oc in
      Caml.Format.fprintf fmt {|#include "internal.h"@.|};
      Pgtypes.write_c ~prefix:"NAME" fmt pg_bindings);
  Out_channel.with_file "NAME_driver.ml" ~f:(fun oc ->
      let fmt = Caml.Format.formatter_of_out_channel oc in
      Caml.Format.fprintf fmt
        {|module Ctypes_bindings = Pgtypes.To_ctypes(MODULE.Def)@.|};
      Caml.Format.fprintf fmt
        {|include Ctypes_bindings.Bindings(Internal)@.|};
        )

let () = run ()
  |ocaml}

let run name =
  let data =
    template
    |> Str.global_replace (Str.regexp_string "NAME") name
    |> Str.global_replace (Str.regexp_string "MODULE") (String.capitalize name)
  in
  Out_channel.write_all "gen.ml" ~data

let () =
  let argv = Sys.get_argv () in
  run argv.(1)
