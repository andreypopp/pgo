let c_prelude =
  {|
#include "pgo_api.h"
#pragma GCC diagnostic ignored "-Wunused-variable"
|}

let generate prefix dirname =
  let module Dummy_fdw : Pgo_fdw_desc.FDW_INTERNAL = struct
    let prefix = prefix

    let validator _ = assert false

    let get_foreign_rel_size _ = assert false

    let begin_foreign_scan _ = assert false

    let end_foreign_scan _ = assert false

    let should_iterate_foreign_scan _ = assert false

    let iterate_foreign_scan _ = assert false

    let rescan_foreign_scan _ = assert false
  end in
  let path basename = Caml.Filename.concat dirname basename in
  let stubs =
    (module Pgo_fdw_desc.Def (Dummy_fdw) : Cstubs_inverted.BINDINGS)
  in
  Out_channel.with_file (path "internal.ml") ~f:(fun oc ->
      Cstubs_inverted.write_ml
        (Caml.Format.formatter_of_out_channel oc)
        ~prefix stubs);
  Out_channel.with_file (path "internal.c") ~f:(fun oc ->
      Caml.Format.fprintf
        (Caml.Format.formatter_of_out_channel oc)
        "%s\n%a" c_prelude
        (Cstubs_inverted.write_c ~prefix)
        stubs);
  Out_channel.with_file (path "internal.h") ~f:(fun oc ->
      Cstubs_inverted.write_c_header
        (Caml.Format.formatter_of_out_channel oc)
        ~prefix stubs)

let () =
  let argv = Sys.get_argv () in
  generate argv.(1) argv.(2)
