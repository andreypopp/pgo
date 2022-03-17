open Pgo_fdw
open Pgo_api

(** Query information about currently running processes. *)
module Ps = struct
  type record = {
    pid : int;
    command : string;
    user : string;
    elapsed : Interval.t Ctypes.ptr;
  }

  let parse_interval v =
    let int = Int.of_string in
    try
      let v = String.strip v in
      let day, v =
        match String.split_on_chars v ~on:[ '-' ] with
        | [ v ] -> (0, v)
        | [ day; v ] -> (Int.of_string day, v)
        | _ -> raise (Failure "Interval.of_string")
      in
      let hour, minute, second =
        match String.split_on_chars v ~on:[ ':' ] with
        | [ second ] -> (0, 0, int second)
        | [ minute; second ] -> (0, int minute, int second)
        | [ hour; minute; second ] -> (int hour, int minute, int second)
        | _ -> raise (Failure "Interval.of_string")
      in
      let v =
        Interval.make ~day (((3600 * hour) + (60 * minute) + second) * 1_000_000)
      in
      Some (Ctypes.allocate Interval.t v)
    with
    | Failure _ ->
      elog Elog_level.info v;
      None

  let parse_record line =
    match String.split_on_chars line ~on:[ ',' ] with
    | [ pid; elapsed; command; user ] ->
      let open Option.Monad_infix in
      (try Some (Int.of_string (String.strip pid)) with
      | Failure _ -> None)
      >>= fun pid ->
      parse_interval elapsed >>= fun elapsed ->
      Some
        {
          pid;
          command = String.strip command;
          user = String.strip user;
          elapsed;
        }
    | _ -> None

  let query () =
    let ic =
      Unix.open_process_args_in "/usr/bin/ps"
        [| "ps"; "--no-header"; "-eo"; "%p,%t,%a,%u" |]
    in
    let lines = In_channel.input_lines ic in
    match Unix.close_process_in ic with
    | Unix.WEXITED 0 -> Ok (List.filter_map lines ~f:parse_record)
    | Unix.WEXITED _
    | Unix.WSIGNALED _
    | Unix.WSTOPPED _ ->
      Error "error running `ps` command"
end

include Make_fdw (struct
  (** Name of the FDW. *)
  let name = "ps_fdw"

  type wrapper_options = unit
  (** Type of FDW options and the corresponding validator. *)

  let validate_wrapper_options = Val_def.const ()

  type server_options = unit
  (** Type of server options and the corresponding validator. *)

  let validate_server_options = Val_def.const ()

  type table_options = { show_command : bool }
  (** Type of table options and the corresponding validator. *)

  let validate_table_options =
    Val_def.(
      let+ show_command = bool_opt "show_command" in
      Ok { show_command = Option.value show_command ~default:false })

  type state = {
    table_options : table_options;
    mutable records : Ps.record list;
  }

  let get_foreign_rel_size rel_info = Rel_opt_info.set_rows rel_info 1000

  let ps_query () =
    match Ps.query () with
    | Ok records -> records
    | Error err -> ereport err
    | exception exn -> ereport (Exn.to_string exn)

  let begin_foreign_scan
      ~wrapper_options:() ~server_options:() ~table_options () =
    { table_options; records = ps_query () }

  let end_foreign_scan _state = ()

  let should_iterate_foreign_scan = function
    | { records = []; _ } -> false
    | _ -> true

  let iterate_foreign_scan state set_column =
    match state.records with
    | [] -> ()
    | record :: records ->
      state.records <- records;
      set_column 0 (Datum.of_int record.pid);
      set_column 1
        (Datum.of_string
           (if state.table_options.show_command then record.command
           else "<REDACTED>"));
      set_column 2 (Datum.of_string record.user);
      set_column 3 (Datum.of_pointer record.elapsed)

  let rescan_foreign_scan state =
    state.records <- ps_query ();
    state
end)
