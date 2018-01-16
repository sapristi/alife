(* * reactions *)
(*   Various functions to deal with calculing the next *)
(*   occuring reaction *)




(* ** pick reaction *)
(*    Picks the next reaction in a list of reactions. *)
(*    Time is not relevant here *)

let pick_reaction (reacs : int * (int * 'a) list) : 'a =
  let rec aux b s l =
    match l with
    | (a, r) :: l' ->
       let s' = a + s in
       if s' > b then r
       else aux b s' l'
    | [] -> failwith "pick_reaction @ reactions.ml : can't find reaction"
  in
  let r = Random.float 1. in
  let a0, rl = reacs in
  let bound = int_of_float (r *. (float_of_int a0)) in
  aux bound 0 rl
