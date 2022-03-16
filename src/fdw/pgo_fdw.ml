module Validate = Validate
open Pgo_api

type set_column = int -> Datum.t -> unit

module type FDW = sig
  open Ctypes

  type state

  type options

  val name : string

  val validate : options Validate.t

  val get_foreign_rel_size : Rel_opt_info.t ptr -> unit

  val begin_foreign_scan : options -> state

  val end_foreign_scan : state -> unit

  val should_iterate_foreign_scan : state -> bool

  val iterate_foreign_scan : state -> set_column -> unit

  val rescan_foreign_scan : state -> state
end

module Make_fdw (Fdw : FDW) : Pgo_fdw_desc.FDW_INTERNAL = struct
  open Ctypes

  type state = { state : Fdw.state; options : Fdw.options }

  let prefix = Fdw.name

  let validate_options opts =
    let fields = Pg_list.to_ptr_list Pgo_typ.Def_elem.t opts in
    Validate.validate Fdw.validate fields

  let validator opts =
    match opts with
    | None -> ()
    | Some opts -> ignore (validate_options opts)

  let get_foreign_rel_size _root baserel _oid =
    Fdw.get_foreign_rel_size baserel;
    setf !@baserel Rel_opt_info.fdw_private null

  let begin_foreign_scan scan_state eflags =
    if Int.logand eflags Exec_flag.explain_only = 0 then
      let options =
        let ss = getf !@scan_state Foreign_scan_state.scan_state in
        let rel = Option.get @@ getf ss Scan_state.currentRelation in
        let oid = getf !@rel Relation_data.rd_id in
        let f_table = getForeignTable oid in
        let options = getf !@f_table Foreign_table.options in
        validate_options options
      in
      let state = Fdw.begin_foreign_scan options in
      setf !@scan_state Pgo_api.Foreign_scan_state.fdw_state
        (Root.create { state; options })

  let end_foreign_scan scan_state =
    let state' = getf !@scan_state Foreign_scan_state.fdw_state in
    Fdw.end_foreign_scan (Root.get state').state;
    Root.release state'

  let should_iterate_foreign_scan scan_state =
    let state' = getf !@scan_state Foreign_scan_state.fdw_state in
    Fdw.should_iterate_foreign_scan (Root.get state').state

  let iterate_foreign_scan _scan_state fdw_state desc values nulls =
    let natts = getf !@desc Tuple_desc.natts in
    let values = CArray.from_ptr values natts in
    let nulls = CArray.from_ptr nulls natts in
    let set_column idx datum =
      CArray.set values idx datum;
      CArray.set nulls idx false
    in
    Fdw.iterate_foreign_scan (Root.get fdw_state).state set_column

  let rescan_foreign_scan scan_state =
    let state' = getf !@scan_state Foreign_scan_state.fdw_state in
    let next_state = Fdw.rescan_foreign_scan (Root.get state').state in
    Root.set state' { state = next_state; options = (Root.get state').options }
end
