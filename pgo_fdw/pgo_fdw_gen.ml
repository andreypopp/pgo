let c_prelude = {|
#include "pgo_api.h"
#pragma GCC diagnostic ignored "-Wunused-variable"
|}

let generate dirname =
  let prefix = "pgo_fdw" in
  let path basename = Filename.concat dirname basename in
  let ml_fd = open_out (path "internal.ml") in
  let c_fd = open_out (path "internal.c") in
  let h_fd = open_out (path "internal.h") in
  let stubs = (module Pgo_fdw_desc.Def(Pgo_fdw_desc.Dummy_fdw): Cstubs_inverted.BINDINGS) in
  begin
    Cstubs_inverted.write_ml 
      (Format.formatter_of_out_channel ml_fd) ~prefix stubs;

    Format.fprintf (Format.formatter_of_out_channel c_fd)
      "%s\n%a" c_prelude (Cstubs_inverted.write_c ~prefix) stubs;

    Cstubs_inverted.write_c_header 
      (Format.formatter_of_out_channel h_fd) ~prefix stubs;

  end;
  close_out h_fd;
  close_out c_fd;
  close_out ml_fd

let () = generate (Sys.argv.(1))
