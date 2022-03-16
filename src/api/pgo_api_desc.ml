module Def (F : Cstubs.FOREIGN) = struct
  open! Ctypes
  open! F
  include Pgo_typ

  let elog = foreign "elog" (Elog_level.t @-> string @-> returning void)

  let ereport = foreign "pgo_api_ereport" (string @-> returning void)

  module Datum = struct
    include Datum

    let of_bool = foreign "BoolGetDatum" (bool @-> returning t)

    let of_string = foreign "pgo_api_Datum_of_string" (string @-> returning t)

    let of_int = foreign "Int64GetDatum" (int @-> returning t)

    let of_float = foreign "Float8GetDatum" (float @-> returning t)

    let of_json_string = foreign "pgo_api_Datum_of_json" (string @-> returning t)
  end

  module Pg_list = struct
    include Pg_list

    let length = foreign "list_length" (ptr Pg_list.t @-> returning int)

    let nth = foreign "list_nth" (ptr Pg_list.t @-> int @-> returning (ptr void))
  end

  let defGetString = foreign "defGetString" (ptr Def_elem.t @-> returning string)

  let defGetBoolean = foreign "defGetBoolean" (ptr Def_elem.t @-> returning bool)

  let getForeignTable =
    foreign "GetForeignTable" (oid @-> returning (ptr Foreign_table.t))

  let getForeignServer =
    foreign "GetForeignServer" (oid @-> returning (ptr Foreign_server.t))

  let getForeignDataWrapper =
    foreign "GetForeignDataWrapper"
      (oid @-> returning (ptr Foreign_data_wrapper.t))
end
