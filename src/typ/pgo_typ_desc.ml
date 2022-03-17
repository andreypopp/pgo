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

  module Exec_flag = struct
    let explain_only = S.constant "EXEC_FLAG_EXPLAIN_ONLY" S.int

    let rewind = S.constant "EXEC_FLAG_REWIND" S.int

    let backward = S.constant "EXEC_FLAG_BACKWARD" S.int

    let mark = S.constant "EXEC_FLAG_MARK" S.int

    let skip_triggers = S.constant "EXEC_FLAG_SKIP_TRIGGERS" S.int

    let with_no_data = S.constant "EXEC_FLAG_WITH_NO_DATA" S.int
  end

  type oid = Unsigned.uint

  let oid = uint

  module Pg_list = struct
    type t

    let t : t structure typ = structure "List"

    let () = seal t
  end

  module Datum = struct
    type t = Uintptr.t

    let t = uintptr_t
  end

  module Interval = struct
    type t

    let t : t structure typ = structure "_Interval"

    let t = typedef t "Interval"

    let time = field t "time" int64_t

    let day = field t "day" int32_t

    let month = field t "month" int32_t

    let () = seal t
  end

  module Tuple_desc = struct
    type s

    type t = s structure ptr

    let t : t structure typ = structure "TupleDescData"

    let natts = field t "natts" int

    let () = seal t
  end

  module Relation_data = struct
    type t

    let t : t structure typ = structure "RelationData"

    let rd_id = field t "rd_id" oid

    let () = seal t
  end

  module Scan_state = struct
    type t

    let t : t structure typ = structure "ScanState"

    let currentRelation = field t "ss_currentRelation" (ptr_opt Relation_data.t)

    let () = seal t
  end

  module Foreign_scan_state = struct
    type t

    let t : t structure typ = structure "ForeignScanState"

    let scan_state = field t "ss" Scan_state.t

    let fdw_state = field t "fdw_state" (ptr void)

    let () = seal t
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

  module Foreign_table = struct
    type t

    let t : t structure typ = structure "ForeignTable"

    let relid = field t "relid" oid

    let serverid = field t "serverid" oid

    let options = field t "options" (ptr_opt Pg_list.t)

    let () = seal t
  end

  module Foreign_server = struct
    type t

    let t : t structure typ = structure "ForeignServer"

    let serverid = field t "serverid" oid

    let fdwid = field t "fdwid" oid

    let owner = field t "owner" oid

    let servername = field t "servername" string

    let servertype = field t "servertype" string_opt

    let serverversion = field t "serverversion" string_opt

    let options = field t "options" (ptr_opt Pg_list.t)

    let () = seal t
  end

  module Foreign_data_wrapper = struct
    type t

    let t : t structure typ = structure "ForeignDataWrapper"

    let fdwid = field t "fdwid" oid

    let owner = field t "owner" oid

    let fdwname = field t "fdwname" string

    let options = field t "options" (ptr_opt Pg_list.t)

    let () = seal t
  end

  module Def_elem = struct
    type t

    let t : t structure typ = structure "DefElem"

    let defname = field t "defname" string

    let () = seal t
  end

  module Oid_class = struct
    let foreignDataWrapperRelationId =
      S.constant "ForeignDataWrapperRelationId" oid

    let foreignServerRelationId = S.constant "ForeignServerRelationId" oid

    let foreignTableRelationId = S.constant "ForeignTableRelationId" oid
  end
end
