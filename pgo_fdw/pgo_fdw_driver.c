#include <caml/callback.h>
#include <sys/stat.h>
#include <unistd.h>

#include "internal.h"
#include "pgo_api.h"

PG_MODULE_MAGIC;

/*
 * SQL functions
 */
extern Datum pgo_fdw_handler(PG_FUNCTION_ARGS);
extern Datum pgo_fdw_validator(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(pgo_fdw_handler);
PG_FUNCTION_INFO_V1(pgo_fdw_validator);

/*
 * FDW callback routines
 */
static void pgoGetForeignRelSize(PlannerInfo *root, RelOptInfo *baserel,
                                 Oid foreigntableid);
static void pgoGetForeignPaths(PlannerInfo *root, RelOptInfo *baserel,
                               Oid foreigntableid);
static ForeignScan *pgoGetForeignPlan(PlannerInfo *root, RelOptInfo *baserel,
                                      Oid foreigntableid,
                                      ForeignPath *best_path, List *tlist,
                                      List *scan_clauses, Plan *outer_plan);
static void pgoBeginForeignScan(ForeignScanState *node, int eflags);
static TupleTableSlot *pgoIterateForeignScan(ForeignScanState *node);
static void pgoReScanForeignScan(ForeignScanState *node);
static void pgoEndForeignScan(ForeignScanState *node);

/*
 * Foreign-data wrapper handler function
 */
Datum pgo_fdw_handler(PG_FUNCTION_ARGS) {
  char *dummy_argv[] = {NULL};
  caml_startup(dummy_argv);

  FdwRoutine *fdwroutine = makeNode(FdwRoutine);

  fdwroutine->GetForeignRelSize = pgoGetForeignRelSize;
  fdwroutine->GetForeignPaths = pgoGetForeignPaths;
  fdwroutine->GetForeignPlan = pgoGetForeignPlan;
  fdwroutine->ExplainForeignScan = NULL;
  fdwroutine->BeginForeignScan = pgoBeginForeignScan;
  fdwroutine->IterateForeignScan = pgoIterateForeignScan;
  fdwroutine->ReScanForeignScan = pgoReScanForeignScan;
  fdwroutine->EndForeignScan = pgoEndForeignScan;
  fdwroutine->AnalyzeForeignTable = NULL;

  PG_RETURN_POINTER(fdwroutine);
}

/*
 * Validate the generic options given to a FOREIGN DATA WRAPPER, SERVER
 * USER MAPPING or FOREIGN TABLE that uses pgo_fdw.
 */
Datum pgo_fdw_validator(PG_FUNCTION_ARGS) {
  /* no-op */
  PG_RETURN_VOID();
}

/*
 * Estimate relation size.
 */
static void pgoGetForeignRelSize(PlannerInfo *root, RelOptInfo *baserel,
                                 Oid foreigntableid) {
  pgo_fdw_getForeignRelSize(root, baserel, foreigntableid);
}

/*
 * Create Possible access paths for a scan on the foreign table
 */
static void pgoGetForeignPaths(PlannerInfo *root, RelOptInfo *baserel,
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
static ForeignScan *pgoGetForeignPlan(PlannerInfo *root, RelOptInfo *baserel,
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
 * Begin scan over table.
 */
static void pgoBeginForeignScan(ForeignScanState *node, int eflags) {
  // Do nothing in EXPLAIN
  if (eflags & EXEC_FLAG_EXPLAIN_ONLY)
    return;

  node->fdw_state = pgo_fdw_beginForeignScan(node, eflags);
}

/*
 * Generate next record and store it into the ScanTupleSlot as a virtual tuple
 */
static TupleTableSlot *pgoIterateForeignScan(ForeignScanState *node) {
  TupleTableSlot *slot = node->ss.ss_ScanTupleSlot;
  ExecClearTuple(slot);

  if (!pgo_fdw_shouldIterateForeignScan(node, node->fdw_state)) {
    return slot;
  }

  Relation rel = node->ss.ss_currentRelation;
  TupleDesc desc = RelationGetDescr(rel);

  // Memory for tuple contents
  Datum *values = (Datum *)palloc0(sizeof(Datum) * desc->natts);

  // Memory for NULL flags
  bool *nulls = (bool *)palloc0(sizeof(bool) * desc->natts);
  memset(nulls, true, sizeof(bool) * desc->natts);

  // Call into OCaml, expect it to fill `values` and `nulls`.
  pgo_fdw_iterateForeignScan(node, node->fdw_state, desc, values, nulls);

  HeapTuple tuple = heap_form_tuple(desc, values, nulls);
  ExecStoreHeapTuple(tuple, slot, false);

  return slot;
}

/*
 * Rescan table, possibly with new parameters
 */
static void pgoReScanForeignScan(ForeignScanState *node) {
  pgo_fdw_rescanForeignScan(node, node->fdw_state);
}

/*
 * Finish scanning foreign table and dispose objects used for this scan
 */
static void pgoEndForeignScan(ForeignScanState *node) {
  pgo_fdw_endForeignScan(node, node->fdw_state);
}
