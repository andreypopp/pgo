open Pgo_fdw
open Pgo_api

let () = Curl.global_init Curl.CURLINIT_GLOBALALL

include Make_fdw (struct
  let name = "github_fdw"

  type wrapper_options = unit

  let validate_wrapper_options = Val_def.const ()

  type server_options = unit

  let validate_server_options = Val_def.(const ())

  type table_options =
    | Table_issues of { repo_owner : string; repo_name : string }

  let validate_table_options =
    Val_def.(
      let* kind = string "kind" in
      match kind with
      | "issues" ->
        Ok
          (let+ repo_owner = string "repo_owner"
           and+ repo_name = string "repo_name" in
           Ok (Table_issues { repo_owner; repo_name }))
      | _ -> Error "invalid kind")

  let make_req server_options endpoint =
    let username =
      match Pgo_api.get_config_option "github.username" with
      | Some v -> v
      | None -> ereport "missing 'github_username' option"
    in
    let access_token =
      match Pgo_api.get_config_option "github.access_token" with
      | Some v -> v
      | None -> ereport "missing 'github_access_token' option"
    in
    let result = Buffer.create 16384 in
    let err = ref "" in
    let write data =
      Buffer.add_string result data;
      String.length data
    in
    try
      let conn = Curl.init () in
      Curl.set_url conn endpoint;
      Curl.set_httpauth conn [ Curl.CURLAUTH_BASIC ];
      Curl.set_username conn username;
      Curl.set_password conn access_token;
      Curl.set_followlocation conn true;
      Curl.set_writefunction conn write;
      Curl.set_errorbuffer conn err;
      Curl.set_useragent conn "Pgo_github_fdw/1";
      Curl.perform conn;
      Curl.cleanup conn;
      let data = Buffer.contents result in
      let json = Yojson.Basic.from_string data in
      Ok json
    with
    | Curl.CurlException _ -> Error !err
    | Yojson.Json_error _ -> Error "error parsing json"
    | Failure s -> Error s

  type state = {
    server_options : server_options;
    table_options : table_options;
    mutable data : Yojson.Basic.t list;
  }

  let get_foreign_rel_size rel_info = Rel_opt_info.set_rows rel_info 1000

  let begin_foreign_scan ~wrapper_options:() ~server_options ~table_options () =
    let data =
      match
        make_req server_options "https://api.github.com/repos/esy/esy/issues"
      with
      | Ok (`List data) -> data
      | Ok _ -> ereport "expected a JSON array"
      | Error err -> ereport err
    in
    { table_options; server_options; data }

  let end_foreign_scan _state = ()

  let should_iterate_foreign_scan = function
    | { data = []; _ } -> false
    | { data = _; _ } -> true

  let iterate_foreign_scan state set_column =
    match state.data with
    | [] -> ()
    | record :: data ->
      state.data <- data;
      set_column 0 (Datum.of_json_string (Yojson.Basic.to_string record))

  let rescan_foreign_scan state =
    begin_foreign_scan ~wrapper_options:() ~server_options:state.server_options
      ~table_options:state.table_options ()
end)
