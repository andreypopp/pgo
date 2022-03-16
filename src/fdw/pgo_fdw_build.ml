open Dune_action_plugin.V1

let spf = Printf.sprintf

let driver_c =
  {|
#include <caml/callback.h>
#include <sys/stat.h>
#include <unistd.h>

#include "internal.h"
#include "pgo_api.h"

PG_MODULE_MAGIC;

/*
 * SQL functions
 */
extern Datum PGO_FDW_PREFIX_handler(PG_FUNCTION_ARGS);
extern Datum PGO_FDW_PREFIX_validator0(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(PGO_FDW_PREFIX_handler);
PG_FUNCTION_INFO_V1(PGO_FDW_PREFIX_validator0);

/*
 * FDW callback routines
 */
static void PGO_FDW_PREFIXGetForeignPaths(PlannerInfo *root, RelOptInfo *baserel,
                               Oid foreigntableid);
static ForeignScan *PGO_FDW_PREFIXGetForeignPlan(PlannerInfo *root, RelOptInfo *baserel,
                                      Oid foreigntableid,
                                      ForeignPath *best_path, List *tlist,
                                      List *scan_clauses, Plan *outer_plan);
static TupleTableSlot *PGO_FDW_PREFIXIterateForeignScan(ForeignScanState *node);

/*
 * Foreign-data wrapper handler function
 */
Datum PGO_FDW_PREFIX_handler(PG_FUNCTION_ARGS) {
  char *dummy_argv[] = {NULL};
  caml_startup(dummy_argv);

  FdwRoutine *fdwroutine = makeNode(FdwRoutine);

  fdwroutine->GetForeignRelSize = PGO_FDW_PREFIX_getForeignRelSize;
  fdwroutine->GetForeignPaths = PGO_FDW_PREFIXGetForeignPaths;
  fdwroutine->GetForeignPlan = PGO_FDW_PREFIXGetForeignPlan;
  fdwroutine->ExplainForeignScan = NULL;
  fdwroutine->BeginForeignScan = PGO_FDW_PREFIX_beginForeignScan;
  fdwroutine->IterateForeignScan = PGO_FDW_PREFIXIterateForeignScan;
  fdwroutine->ReScanForeignScan = PGO_FDW_PREFIX_rescanForeignScan;
  fdwroutine->EndForeignScan = PGO_FDW_PREFIX_endForeignScan;
  fdwroutine->AnalyzeForeignTable = NULL;

  PG_RETURN_POINTER(fdwroutine);
}

/*
 * Validate the generic options given to a FOREIGN DATA WRAPPER, SERVER
 * USER MAPPING or FOREIGN TABLE that uses PGO_FDW_PREFIX.
 */
Datum PGO_FDW_PREFIX_validator0(PG_FUNCTION_ARGS) {
  char *dummy_argv[] = {NULL};
  caml_startup(dummy_argv);
	List *options = untransformRelOptions(PG_GETARG_DATUM(0));
  PGO_FDW_PREFIX_validator(options);
  PG_RETURN_VOID();
}

/*
 * Create Possible access paths for a scan on the foreign table
 */
static void PGO_FDW_PREFIXGetForeignPaths(PlannerInfo *root, RelOptInfo *baserel,
                               Oid foreigntableid) {
  add_path(baserel,
           (Path *)create_foreignscan_path(root, baserel, NULL, baserel->rows,
                                           10,   // startup_cost
                                           1000, // total_cost
                                           NIL,  // no pathkeys
                                           NULL, // no outer rel either
                                           NULL, // no extra plan
                                           NIL));
}

/*
 * Create a ForeignScan plan node for scanning the foreign table
 */
static ForeignScan *PGO_FDW_PREFIXGetForeignPlan(PlannerInfo *root, RelOptInfo *baserel,
                                      Oid foreigntableid,
                                      ForeignPath *best_path, List *tlist,
                                      List *scan_clauses, Plan *outer_plan) {
  scan_clauses = extract_actual_clauses(scan_clauses, false);
  return make_foreignscan(tlist, scan_clauses, baserel->relid, NIL,
                          best_path->fdw_private, NIL, // no custom tlist
                          NIL,                         // no remote quals
                          outer_plan);
}

/*
 * Generate next record and store it into the ScanTupleSlot as a virtual tuple
 */
static TupleTableSlot *PGO_FDW_PREFIXIterateForeignScan(ForeignScanState *node) {
  TupleTableSlot *slot = node->ss.ss_ScanTupleSlot;
  ExecClearTuple(slot);

  if (!PGO_FDW_PREFIX_shouldIterateForeignScan(node)) return slot;

  Relation rel = node->ss.ss_currentRelation;
  TupleDesc desc = RelationGetDescr(rel);

  // Memory for tuple contents
  Datum *values = (Datum *)palloc0(sizeof(Datum) * desc->natts);

  // Memory for NULL flags
  bool *nulls = (bool *)palloc0(sizeof(bool) * desc->natts);
  memset(nulls, true, sizeof(bool) * desc->natts);

  // Call into OCaml, expect it to fill `values` and `nulls`.
  PGO_FDW_PREFIX_iterateForeignScan(node, node->fdw_state, desc, values, nulls);

  HeapTuple tuple = heap_form_tuple(desc, values, nulls);
  ExecStoreHeapTuple(tuple, slot, false);

  return slot;
}
|}

let action prefix =
  let open O in
  let filename_driver_c = Path.of_string @@ spf "%s_driver.c" prefix in
  let filename_driver_ml = Path.of_string @@ spf "%s_driver.ml" prefix in
  let+ () =
    let template_prefix = Str.regexp "PGO_FDW_PREFIX" in
    let driver_c = Str.global_replace template_prefix prefix driver_c in
    write_file ~path:filename_driver_c ~data:driver_c
  and+ () =
    write_file ~path:filename_driver_ml
      ~data:(spf {|include Pgo_fdw_desc.Def (Example_fdw) (Internal)|})
  in
  ()

let () = run (action Sys.argv.(1))
