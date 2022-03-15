module Def (S : Cstubs_structs.TYPE) = struct
  open! Ctypes
  open! S

  module Elog_level = struct
    type t = int

    let t = int

    let debug5 = S.constant "DEBUG5" S.int

    let debug4 = S.constant "DEBUG4" S.int

    let debug3 = S.constant "DEBUG3" S.int

    let debug2 = S.constant "DEBUG2" S.int

    let debug1 = S.constant "DEBUG1" S.int

    let log = S.constant "LOG" S.int

    let info = S.constant "INFO" S.int

    let notice = S.constant "NOTICE" S.int

    let warning = S.constant "WARNING" S.int

    let error = S.constant "ERROR" S.int

    let fatal = S.constant "FATAL" S.int

    let panic = S.constant "PANIC" S.int
  end

  type oid = Unsigned.uint

  let oid = uint

  module Datum = struct
    type t = Uintptr.t

    let t = uintptr_t
  end

  module Tuple_desc = struct
    type s

    type t = s structure ptr

    let t : t structure typ = structure "TupleDescData"

    let natts = field t "natts" int

    let () = seal t
  end

  module Foreign_scan_state = struct
    type t

    let t : t structure typ = structure "ForeignScanState"
  end

  module Planner_info = struct
    type t

    let t : t structure typ = structure "PlannerInfo"
  end

  module Rel_opt_info = struct
    type s

    type t = s structure

    let t : s structure typ = structure "RelOptInfo"

    let rows = field t "rows" int

    let fdw_private = field t "fdw_private" (ptr void)

    let () = seal t
  end
end
