let c_headers = {|
#include "pgo_typ.h"
|}

let main () =
  let argv = Sys.get_argv () in
  let filename = argv.(1) in
  Out_channel.with_file filename ~f:(fun oc ->
      let fmt = Caml.Format.formatter_of_out_channel oc in
      Caml.Format.fprintf fmt "%s@\n" c_headers;
      Cstubs_structs.write_c fmt (module Pgo_typ_desc.Def);
      Caml.Format.pp_print_flush fmt ())

let () = main ()
