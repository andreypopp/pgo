let c_prelude =
  {|
#include "pgo_api.h"
#pragma GCC diagnostic ignored "-Wunused-variable"
|}

let generate prefix dirname =
  let module Dummy_fdw : Pgo_fdw_desc.FDW_INTERNAL = struct
    let prefix = prefix

    let get_foreign_rel_size _ = assert false

    let begin_foreign_scan _ = assert false

    let end_foreign_scan _ = assert false

    let should_iterate_foreign_scan _ = assert false

    let iterate_foreign_scan _ = assert false

    let rescan_foreign_scan _ = assert false
  end in
  let path basename = Filename.concat dirname basename in
  let ml_fd = open_out (path "internal.ml") in
  let c_fd = open_out (path "internal.c") in
  let h_fd = open_out (path "internal.h") in
  let stubs =
    (module Pgo_fdw_desc.Def (Dummy_fdw) : Cstubs_inverted.BINDINGS)
  in
  Cstubs_inverted.write_ml (Format.formatter_of_out_channel ml_fd) ~prefix stubs;

  Format.fprintf
    (Format.formatter_of_out_channel c_fd)
    "%s\n%a" c_prelude
    (Cstubs_inverted.write_c ~prefix)
    stubs;

  Cstubs_inverted.write_c_header
    (Format.formatter_of_out_channel h_fd)
    ~prefix stubs;

  close_out h_fd;
  close_out c_fd;
  close_out ml_fd

let () = generate Sys.argv.(1) Sys.argv.(2)
