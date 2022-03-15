open Ctypes
open Pgo_typ

module type FDW_INTERNAL = sig
  open Ctypes

  val prefix : string

  val get_foreign_rel_size :
    Planner_info.t structure ptr -> Rel_opt_info.t ptr -> oid -> unit

  val begin_foreign_scan : Foreign_scan_state.t structure ptr -> int -> unit ptr

  val end_foreign_scan : Foreign_scan_state.t structure ptr -> unit ptr -> unit

  val should_iterate_foreign_scan :
    Foreign_scan_state.t structure ptr -> unit ptr -> bool

  val iterate_foreign_scan :
    Foreign_scan_state.t structure ptr ->
    unit ptr ->
    Tuple_desc.t structure ptr ->
    Datum.t ptr ->
    bool ptr ->
    unit

  val rescan_foreign_scan :
    Foreign_scan_state.t structure ptr -> unit ptr -> unit
end

module Def (Api : FDW_INTERNAL) (I : Cstubs_inverted.INTERNAL) = struct
  let () = I.typedef Planner_info.t "PlannerInfo"

  let () = I.typedef Foreign_scan_state.t "ForeignScanState"

  let () = I.typedef (ptr Tuple_desc.t) "TupleDesc"

  let () = I.typedef Rel_opt_info.t "RelOptInfo"

  let spf = Printf.sprintf

  let () =
    I.internal
      (spf "%s_getForeignRelSize" Api.prefix)
      (ptr Planner_info.t @-> ptr Rel_opt_info.t @-> oid @-> returning void)
      Api.get_foreign_rel_size

  let () =
    I.internal
      (spf "%s_beginForeignScan" Api.prefix)
      (ptr Foreign_scan_state.t @-> int @-> returning (ptr void))
      Api.begin_foreign_scan

  let () =
    I.internal
      (spf "%s_endForeignScan" Api.prefix)
      (ptr Foreign_scan_state.t @-> ptr void @-> returning void)
      Api.end_foreign_scan

  let () =
    I.internal
      (spf "%s_shouldIterateForeignScan" Api.prefix)
      (ptr Foreign_scan_state.t @-> ptr void @-> returning bool)
      Api.should_iterate_foreign_scan

  let () =
    I.internal
      (spf "%s_iterateForeignScan" Api.prefix)
      (ptr Foreign_scan_state.t
      @-> ptr void
      @-> ptr Tuple_desc.t
      @-> ptr Datum.t
      @-> ptr bool
      @-> returning void)
      Api.iterate_foreign_scan

  let () =
    I.internal
      (spf "%s_rescanForeignScan" Api.prefix)
      (ptr Foreign_scan_state.t @-> ptr void @-> returning void)
      Api.rescan_foreign_scan
end
