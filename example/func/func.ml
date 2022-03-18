module Def (I : Pgtypes.INTERNAL) = struct
  open Pgtypes

  let () = I.func "func_add" (int @-> int @-> returning int) (fun a b -> a + b)
end
