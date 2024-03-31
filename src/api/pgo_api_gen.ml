let c_headers = {|
#include "pgo_api.h"
|}

let () =
  let argv = Sys.get_argv () in
  let mode = argv.(1) in
  let filename = argv.(2) in
  Out_channel.with_file filename ~f:(fun oc ->
      let fmt = Stdlib.Format.formatter_of_out_channel oc in
      let fn =
        match mode with
        | "ml" -> Cstubs.write_ml
        | "c" ->
          Stdlib.Format.fprintf fmt "%s@\n" c_headers;
          Cstubs.write_c
        | _ -> assert false
      in
      fn ~concurrency:Cstubs.unlocked fmt ~prefix:"pgo_api"
        (module Pgo_api_desc.Def);
      Stdlib.Format.pp_print_flush fmt ())
