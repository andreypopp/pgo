module Def (S : Cstubs_structs.TYPE) = struct
  open! Ctypes
  open! S

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
