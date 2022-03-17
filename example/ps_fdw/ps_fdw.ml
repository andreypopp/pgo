(** Query information about currently running processes. *)
module Ps = struct
  type record = { pid : int; command : string; user : string; time : string }

  let query () =
    let ic =
      Unix.open_process_args_in "/usr/bin/ps" [| "ps"; "-eo"; "%p,%t,%a,%u" |]
    in
    let lines =
      match In_channel.input_lines ic with
      | [] -> []
      | _ :: xs -> xs
    in
    match Unix.close_process_in ic with
    | Unix.WEXITED 0 ->
      Ok
        (List.filter_map lines ~f:(fun line ->
             match String.split_on_chars line ~on:[ ',' ] with
             | [ pid; time; command; user ] ->
               Some
                 {
                   pid = Int.of_string (String.strip pid);
                   command = String.strip command;
                   user = String.strip user;
                   time = String.strip time;
                 }
             | _ -> None))
    | Unix.WEXITED _
    | Unix.WSIGNALED _
    | Unix.WSTOPPED _ ->
      Error "error running `ps` command"
end

open Pgo_fdw
open Pgo_api

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

  let begin_foreign_scan
      ~wrapper_options:() ~server_options:() ~table_options () =
    {
      table_options;
      records =
        (match Ps.query () with
        | Ok records -> records
        | Error err -> ereport err);
    }

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
      set_column 3 (Datum.of_string record.time)

  let rescan_foreign_scan state =
    state.records <-
      (match Ps.query () with
      | Ok records -> records
      | Error err -> ereport err);
    state
end)
