include Pgo_api_desc.Def (Internal)

let elogf lvl fmt =
  let kerr _ =
    let message = Caml.Format.flush_str_formatter () in
    elog lvl message
  in
  Caml.Format.kfprintf kerr Caml.Format.str_formatter fmt

let ereport msg =
  ereport msg;
  assert false

let ereportf fmt =
  let kerr _ =
    let message = Caml.Format.flush_str_formatter () in
    ereport message
  in
  Caml.Format.kfprintf kerr Caml.Format.str_formatter fmt

module Rel_opt_info = struct
  include Rel_opt_info

  let set_rows rel v = Ctypes.(setf !@rel rows v)
end

module Pg_list = struct
  type t = Pg_list.t Ctypes.structure Ctypes_static.ptr

  let length (xs : t) = Pg_list.length xs

  let nth (xs : t) n = Pg_list.nth xs n

  let iter ~f xs =
    let len = length xs in
    let n = ref 0 in
    while !n < len do
      f (nth xs !n);
      n := !n + 1
    done

  let fold_left ~init ~f xs =
    let acc = ref init in
    iter xs ~f:(fun x -> acc := f !acc x);
    !acc

  let to_ptr_list typ =
    fold_left ~init:[] ~f:(fun acc ptr -> Ctypes.from_voidp typ ptr :: acc)
end

module Def_elem = struct
  open Ctypes

  type t = Def_elem.t structure ptr

  let defname v = getf !@v Def_elem.defname

  let get_string v = defGetString v

  let get_bool v = defGetBoolean v
end
