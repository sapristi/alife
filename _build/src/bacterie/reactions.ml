let reaction_constant = 0.001


(* à améliorer ? *)
let react (n : int) (m : int) : bool = 
  let r = Random.float 1. in
  r < (reaction_constant *. (float_of_int n) *. (float_of_int m))
    
