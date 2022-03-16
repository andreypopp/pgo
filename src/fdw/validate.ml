type _ t =
  | Val_const : 'a -> 'a t
  | Val_string : string -> string t
  | Val_bool : string -> bool t
  | Val_map : 'a t * ('a -> ('b, string) result) -> 'b t
  | Val_both : 'a t * 'b t -> ('a * 'b) t

let const v = Val_const v

let string name = Val_string name

let map v f = Val_map (v, f)

let both a b = Val_both (a, b)

let ( let+ ) = map

let ( and+ ) = both

let validate schema (options : Pgo_api.Def_elem.t list) =
  let seen = ref [] in
  let find name =
    match
      List.find_opt
        (fun def -> String.equal (Pgo_api.Def_elem.defname def) name)
        options
    with
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
    | Val_both (a, b) -> (aux a, aux b)
    | Val_string name -> Pgo_api.Def_elem.get_string (find name)
    | Val_bool name -> Pgo_api.Def_elem.get_bool (find name)
  in
  let v = aux schema in
  List.iter
    (fun def ->
      let name = Pgo_api.Def_elem.defname def in
      match List.find_opt (String.equal name) !seen with
      | None -> Pgo_api.ereportf "unknown option \"%s\"" name
      | Some _ -> ())
    options;
  v
