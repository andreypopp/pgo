module Def (F : Cstubs.FOREIGN) = struct
  open! Ctypes
  open! F
  include Pgo_def
  include Pgo_typ

  let elog = foreign "elog" (Elog_level.t @-> string @-> returning void)

  module Datum = struct
    include Datum

    let of_bool = foreign "BoolGetDatum" (bool @-> returning t)

    let of_string = foreign "pgo_api_Datum_of_string" (string @-> returning t)

    let of_int = foreign "Int64GetDatum" (int @-> returning t)

    let of_float = foreign "Float8GetDatum" (float @-> returning t)

    let of_json_string = foreign "pgo_api_Datum_of_json" (string @-> returning t)
  end
end
