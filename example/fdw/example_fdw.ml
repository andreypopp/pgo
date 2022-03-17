open Pgo_fdw

type process = { pid : int; command : string; user : string; time : string }

let get_process_list () =
  let ic =
    Unix.open_process_args_in "/usr/bin/ps" [| "ps"; "-eo"; "%p,%t,%a,%u" |]
  in
  let lines =
    match Stdio.In_channel.input_lines ic with
    | [] -> []
    | _ :: xs -> xs
  in
  match Unix.close_process_in ic with
  | Unix.WEXITED 0 ->
    Ok
      (List.filter_map
         (fun line ->
           match String.split_on_char ',' line with
           | [ pid; time; command; user ] ->
             Some
               {
                 pid = int_of_string (String.trim pid);
                 command = String.trim command;
                 user = String.trim user;
                 time = String.trim time;
               }
           | _ -> None)
         lines)
  | Unix.WEXITED _
  | Unix.WSIGNALED _
  | Unix.WSTOPPED _ ->
    Error "error running `ps` command"

include Make_fdw (struct
  open Pgo_api

  let name = "example_fdw"

  (* ps -eo "%p,%a,%u,%t" *)

  type wrapper_options = unit

  let validate_wrapper_options = Val_def.const ()

  type server_options = unit

  let validate_server_options = Val_def.const ()

  type table_options = { city : string }

  let validate_table_options =
    Val_def.(
      let+ city = string "city" in
      Ok { city })

  type state = { mutable process_list : process list }

  let get_foreign_rel_size rel_info = Rel_opt_info.set_rows rel_info 1000

  let begin_foreign_scan
      ~wrapper_options:() ~server_options:() ~table_options:options () =
    {
      process_list =
        (match get_process_list () with
        | Ok ps -> ps
        | Error err -> ereport err);
    }

  let end_foreign_scan _state = ()

  let should_iterate_foreign_scan state = List.length state.process_list > 0

  let iterate_foreign_scan state set_column =
    match state.process_list with
    | [] -> ()
    | process :: process_list ->
      state.process_list <- process_list;
      set_column 0 (Datum.of_int process.pid);
      set_column 1 (Datum.of_string process.command);
      set_column 2 (Datum.of_string process.user);
      set_column 3 (Datum.of_string process.time)

  let rescan_foreign_scan state =
    state.process_list <-
      (match get_process_list () with
      | Ok ps -> ps
      | Error err -> ereport err);
    state
end)
