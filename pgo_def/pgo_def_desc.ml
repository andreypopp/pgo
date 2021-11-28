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
end
