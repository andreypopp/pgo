type _ t =
  | Val_const : 'a -> 'a t
  | Val_string : string -> string t
  | Val_string_opt : string -> string option t
  | Val_bool : string -> bool t
  | Val_bool_opt : string -> bool option t
  | Val_map : 'a t * ('a -> ('b, string) Result.t) -> 'b t
  | Val_bind : 'a t * ('a -> ('b t, string) Result.t) -> 'b t
  | Val_both : 'a t * 'b t -> ('a * 'b) t

let const v = Val_const v

let string name = Val_string name

let string_opt name = Val_string_opt name

let bool name = Val_bool name

let bool_opt name = Val_bool_opt name

let map v f = Val_map (v, f)

let bind v f = Val_bind (v, f)

let both a b = Val_both (a, b)

let ( let* ) = bind

let ( let+ ) = map

let ( and+ ) = both

let validate schema (options : Pgo_api.Def_elem.t list) =
  let seen = ref [] in
  let find_opt name =
    match
      List.find options ~f:(fun def ->
          String.equal (Pgo_api.Def_elem.defname def) name)
    with
    | None -> None
    | Some def ->
      seen := name :: !seen;
      Some def
  in
  let find name =
    match find_opt name with
    | None -> Pgo_api.ereportf "missing option \"%s\"" name
    | Some def ->
      seen := name :: !seen;
      def
  in
  let rec aux : type a. a t -> a = function
    | Val_const v -> v
    | Val_map (v, f) -> (
      match f (aux v) with
      | Ok v -> v
      | Error err -> Pgo_api.ereport err)
    | Val_bind (v, f) -> (
      match f (aux v) with
      | Ok v -> aux v
      | Error err -> Pgo_api.ereport err)
    | Val_both (a, b) -> (aux a, aux b)
    | Val_string name -> Pgo_api.Def_elem.get_string (find name)
    | Val_string_opt name ->
      Option.map (find_opt name) ~f:Pgo_api.Def_elem.get_string
    | Val_bool name -> Pgo_api.Def_elem.get_bool (find name)
    | Val_bool_opt name ->
      Option.map (find_opt name) ~f:Pgo_api.Def_elem.get_bool
  in
  let v = aux schema in
  List.iter options ~f:(fun def ->
      let name = Pgo_api.Def_elem.defname def in
      match List.find !seen ~f:(String.equal name) with
      | None -> Pgo_api.ereportf "unknown option \"%s\"" name
      | Some _ -> ());
  v
