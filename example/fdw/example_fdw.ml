open Pgo_fdw

include Make_fdw (struct
  open Pgo_api

  let name = "example_fdw"

  type wrapper_options = unit

  let validate_wrapper_options = Val_def.const ()

  type server_options = unit

  let validate_server_options = Val_def.const ()

  type table_options = { city : string }

  let validate_table_options =
    Val_def.(
      let+ city = string "city" in
      Ok { city })

  type state = { mutable rownum : int; options : table_options }

  let get_foreign_rel_size rel_info = Rel_opt_info.set_rows rel_info 1000

  let begin_foreign_scan
      ~wrapper_options:() ~server_options:() ~table_options:options () =
    { rownum = 0; options }

  let end_foreign_scan _state = ()

  let should_iterate_foreign_scan state = state.rownum < 1000

  let iterate_foreign_scan state set_column =
    state.rownum <- state.rownum + 1;
    set_column 0
      (Datum.of_string (state.options.city ^ Int.to_string state.rownum));
    set_column 1 (Datum.of_int state.rownum);
    set_column 2 (Datum.of_float (Float.of_int state.rownum));
    set_column 3 (Datum.of_bool (state.rownum mod 2 = 0));
    set_column 4 (Datum.of_json_string "{}")

  let rescan_foreign_scan state =
    state.rownum <- 0;
    state
end)
