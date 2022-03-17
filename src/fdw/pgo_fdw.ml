module Val_def = Val_def
open Pgo_api

type set_column = int -> Datum.t -> unit

module type FDW = sig
  open Ctypes

  val name : string

  type wrapper_options

  val validate_wrapper_options : wrapper_options Val_def.t

  type server_options

  val validate_server_options : server_options Val_def.t

  type table_options

  val validate_table_options : table_options Val_def.t

  val get_foreign_rel_size : Rel_opt_info.t ptr -> unit

  type state

  val begin_foreign_scan :
    wrapper_options:wrapper_options ->
    server_options:server_options ->
    table_options:table_options ->
    unit ->
    state

  val end_foreign_scan : state -> unit

  val should_iterate_foreign_scan : state -> bool

  val iterate_foreign_scan : state -> set_column -> unit

  val rescan_foreign_scan : state -> state
end

module Make_fdw (Fdw : FDW) : Pgo_fdw_desc.FDW_INTERNAL = struct
  open Ctypes

  let prefix = Fdw.name

  let validate_opts validator opts =
    Val_def.validate validator
      (opts
      |> Option.map ~f:(Pg_list.to_ptr_list Pgo_typ.Def_elem.t)
      |> Option.value ~default:[])

  let validator opts oid =
    if Unsigned.UInt.equal oid Pgo_api.Oid_class.foreignDataWrapperRelationId
    then ignore (validate_opts Fdw.validate_wrapper_options opts)
    else if Unsigned.UInt.equal oid Pgo_api.Oid_class.foreignServerRelationId
    then ignore (validate_opts Fdw.validate_server_options opts)
    else if Unsigned.UInt.equal oid Pgo_api.Oid_class.foreignTableRelationId
    then ignore (validate_opts Fdw.validate_table_options opts)
    else ereport "unable to validate options for an unknown object"

  let get_foreign_rel_size _root baserel _oid =
    Fdw.get_foreign_rel_size baserel;
    setf !@baserel Rel_opt_info.fdw_private null

  let begin_foreign_scan scan_state eflags =
    if eflags land Exec_flag.explain_only = 0 then
      let f_table =
        let ss = getf !@scan_state Foreign_scan_state.scan_state in
        let rel = Option.value_exn (getf ss Scan_state.currentRelation) in
        let oid = getf !@rel Relation_data.rd_id in
        getForeignTable oid
      in
      let table_options =
        let options = getf !@f_table Foreign_table.options in
        validate_opts Fdw.validate_table_options options
      in
      let f_server = getForeignServer (getf !@f_table Foreign_table.serverid) in
      let server_options =
        let options = getf !@f_server Foreign_server.options in
        validate_opts Fdw.validate_server_options options
      in
      let wrapper_options =
        let fdw =
          getForeignDataWrapper (getf !@f_server Foreign_server.fdwid)
        in
        let options = getf !@fdw Foreign_data_wrapper.options in
        validate_opts Fdw.validate_wrapper_options options
      in
      let state =
        Fdw.begin_foreign_scan ~wrapper_options ~server_options ~table_options
          ()
      in
      setf !@scan_state Pgo_api.Foreign_scan_state.fdw_state (Root.create state)

  let end_foreign_scan scan_state =
    let state' = getf !@scan_state Foreign_scan_state.fdw_state in
    Fdw.end_foreign_scan (Root.get state');
    Root.release state'

  let should_iterate_foreign_scan scan_state =
    let state' = getf !@scan_state Foreign_scan_state.fdw_state in
    Fdw.should_iterate_foreign_scan (Root.get state')

  let iterate_foreign_scan _scan_state fdw_state desc values nulls =
    let natts = getf !@desc Tuple_desc.natts in
    let values = CArray.from_ptr values natts in
    let nulls = CArray.from_ptr nulls natts in
    let set_column idx datum =
      CArray.set values idx datum;
      CArray.set nulls idx false
    in
    Fdw.iterate_foreign_scan (Root.get fdw_state) set_column

  let rescan_foreign_scan scan_state =
    let state' = getf !@scan_state Foreign_scan_state.fdw_state in
    let next_state = Fdw.rescan_foreign_scan (Root.get state') in
    Root.set state' next_state
end
