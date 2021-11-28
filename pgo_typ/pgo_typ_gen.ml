let c_headers = {|
#include "pgo_typ.h"
|}

let main () =
  let filename = Array.get Sys.argv 1 in
  let stubs_out = open_out filename in
  let stubs_fmt = Format.formatter_of_out_channel stubs_out in
  Format.fprintf stubs_fmt "%s@\n" c_headers;
  Cstubs_structs.write_c stubs_fmt (module Pgo_typ_desc.Def);
  Format.pp_print_flush stubs_fmt ();
  close_out stubs_out

let () = main ()
