open Pgo_api

type set_column = int -> Datum.t -> unit

module type FDW = sig
  open Ctypes

  type state

  val get_foreign_rel_size : Rel_opt_info.t ptr -> unit

  val begin_foreign_scan : unit -> state

  val end_foreign_scan : state -> unit

  val should_iterate_foreign_scan : state -> bool

  val iterate_foreign_scan : state -> set_column -> unit

  val rescan_foreign_scan : state -> state
end

module Make_fdw (Fdw : FDW) : Pgo_fdw_desc.FDW_INTERNAL = struct
  open Ctypes

  let get_foreign_rel_size _root baserel _oid =
    Fdw.get_foreign_rel_size baserel;
    setf !@baserel Rel_opt_info.fdw_private null

  let begin_foreign_scan _scan_state _eflags =
    let state = Fdw.begin_foreign_scan () in
    Root.create state

  let end_foreign_scan _scan_state fdw_state =
    Fdw.end_foreign_scan (Root.get fdw_state);
    Root.release fdw_state

  let should_iterate_foreign_scan _scan_state fdw_state =
    let state = Root.get fdw_state in
    Fdw.should_iterate_foreign_scan state

  let iterate_foreign_scan _scan_state fdw_state desc values nulls =
    let state = Root.get fdw_state in
    let natts = getf !@desc Tuple_desc.natts in
    let values = CArray.from_ptr values natts in
    let nulls = CArray.from_ptr nulls natts in
    let set_column idx datum =
      CArray.set values idx datum;
      CArray.set nulls idx false
    in
    Fdw.iterate_foreign_scan state set_column

  let rescan_foreign_scan _scan_state fdw_state =
    let state = Root.get fdw_state in
    let next_state = Fdw.rescan_foreign_scan state in
    Root.set fdw_state next_state
end
