include Pgo_api_desc.Def (Internal)

let elogf lvl fmt =
  let kerr _ =
    let message = Format.flush_str_formatter () in
    elog lvl message
  in
  Format.kfprintf kerr Format.str_formatter fmt

module Rel_opt_info = struct
  include Rel_opt_info

  let set_rows rel v = Ctypes.(setf !@rel rows v)
end
