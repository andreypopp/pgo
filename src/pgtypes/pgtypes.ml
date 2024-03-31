type _ typ = Typ_int : int typ

type _ fn =
  | Fn_arr : ('a typ * 'b fn) -> ('a -> 'b) fn
  | Fn_return : 'a typ -> 'a fn

let int = Typ_int

let returning typ = Fn_return typ

let ( @-> ) arg return = Fn_arr (arg, return)

let typ_to_ctypes : type a. a typ -> a Ctypes_static.typ = function
  | Typ_int -> Ctypes_static.int

let rec fn_to_ctypes : type a b. (a -> b) fn -> (a -> b) Ctypes.fn = function
  | Fn_arr (a, Fn_return b) ->
    Ctypes.(typ_to_ctypes a @-> returning (typ_to_ctypes b))
  | Fn_arr (a, (Fn_arr _ as b)) -> Ctypes.(typ_to_ctypes a @-> fn_to_ctypes b)
  | Fn_return _ -> .

type packed_typ = Pack_typ : 'a typ -> packed_typ

let rec fn_args : type a. a fn -> packed_typ list = function
  | Fn_arr (typ, next) -> Pack_typ typ :: fn_args next
  | Fn_return _ -> []

let rec fn_returning : type a. a fn -> packed_typ = function
  | Fn_arr (typ, next) -> fn_returning next
  | Fn_return typ -> Pack_typ typ

module type INTERNAL = sig
  val func : string -> ('a -> 'b) fn -> ('a -> 'b) -> unit
end

module type BINDINGS = functor (I : INTERNAL) -> sig end

type func = Func : string * ('a -> 'b) fn * ('a -> 'b) -> func

module To_ctypes (Def : BINDINGS) : sig
  val funcs : func list

  module Bindings : Cstubs_inverted.BINDINGS
end = struct
  let funcs = ref []

  module _ = Def (struct
    let func name sign impl = funcs := Func (name, sign, impl) :: !funcs
  end)

  let funcs = !funcs

  module Bindings (I : Cstubs_inverted.INTERNAL) = struct
    List.iter funcs ~f:(function Func (name, pg_sign, impl) ->
        let name = Printf.sprintf "%s0" name in
        let c_sign = fn_to_ctypes pg_sign in
        I.internal name c_sign impl)
  end
end

let to_ctypes (module Def : BINDINGS) =
  let funcs = ref [] in
  let module Bindings = Def (struct
    let func name sign impl = funcs := Func (name, sign, impl) :: !funcs
  end) in
  let module Res = To_ctypes (Def) in
  (module Res.Bindings : Cstubs_inverted.BINDINGS)

let pf = Stdlib.Format.fprintf

let write_c ~prefix fmt (module Def : BINDINGS) =
  let funcs = ref [] in
  let module Bindings = Def (struct
    let func name sign impl = funcs := Func (name, sign, impl) :: !funcs
  end) in
  let funcs = !funcs in
  pf fmt
    {|
#include "pgo_api.h"
#include <caml/callback.h>
PG_MODULE_MAGIC;
void _PG_init(void) {
  char *dummy_argv[] = {NULL};
  caml_startup(dummy_argv);
}@.|};
  List.iter funcs ~f:(function Func (name, _, _) ->
      pf fmt {|PG_FUNCTION_INFO_V1(%s);@.|} name);
  List.iter funcs ~f:(function Func (name, fn, _) ->
      pf fmt {|Datum %s(PG_FUNCTION_ARGS) {@.|} name;
      let args =
        List.mapi (fn_args fn) ~f:(fun n typ ->
            let name = Printf.sprintf "x%i" n in
            (name, typ))
      in
      List.iteri args ~f:(fun n (name, Pack_typ typ) ->
          match typ with
          | Typ_int ->
            pf fmt {|  %a = PG_GETARG_INT32(%i);@.|} (Ctypes.format_typ ~name)
              (typ_to_ctypes typ) n);
      let (Pack_typ ret_ty) = fn_returning fn in
      let pp_callargs fmt args =
        pf fmt "%s" (String.concat ~sep:", " (List.map args ~f:fst))
      in
      pf fmt {|  %a = %s0(%a);@.|}
        (Ctypes.format_typ ~name:"returning")
        (typ_to_ctypes ret_ty) name pp_callargs args;
      (match ret_ty with
      | Typ_int -> pf fmt {|  PG_RETURN_INT32(returning);@.|});
      pf fmt {|}@.|})
