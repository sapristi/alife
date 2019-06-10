open Local_libs
open Misc_library

(* * File overview *)

(* This file contains the functions used by the reactions to define what  *)
(* happens when the reaction is triggered.  *)
(* The functions are externalised in this file to allow easy configuration *)
(* of implementation details *)

(* * asymetric_grab auxiliary function *)
let asymetric_grab mol pnet = 
  let grabs = Petri_net.get_possible_mol_grabs mol pnet
  in
  if not (grabs = [])
  then
    let grab,pid = random_pick_from_list grabs in
    match grab with
    | pos -> Petri_net.grab mol pos pid pnet
  else
    false

(* * break function *)
let break mol =
  let n = String.length mol in
  let b = 1+ Random.int (n-1) in
  (String.sub mol 0 b, String.sub mol b (n-b))


let break_l mol = 
  let n = String.length mol in
  let b = 1+ Random.int (n-1) in
  [String.sub mol 0 b; String.sub mol b (n-b)]


(* * collision *)
(* The result of a collision is a reorganisation of *)
(* both colliding molecules. Each operation happens  *)
(* with a configurable probabily: *)
(*  - each colliding molecule can break in two pieces *)
(*  - each resulting piece can be flipped *)
(*  - the pieces will then form new molecules *)
(*    by concatenation. *)
  
let collide mol1 mol2 =
  let rec random_flip m =
    if bernouil_f 0.5
    then
      let l = String.length m in 
      String.init l (fun i -> m.[l-i-1])
    else m
  and mix l =
    let res = ref []
    and ll = List.length l in 

    for i = 0 to ll - 1  do
      res := (List.nth l (Random.int (ll - i - 1))) ::  !res
    done;
    !res
    
  and aux l res =
    match l, res with
    | [], _ -> res
    | h::[],  [] -> [h]
    | h::t, [] -> aux t [h]
    | h::t, h'::t' ->
       let res' = 
         if bernouil_f 0.5
         then (h^h') :: res
         else h :: res
       in aux t res'

  in
  let mols = ((if bernouil_f 0.5
              then break_l mol1 else [mol1])
             @ (if bernouil_f 0.5
                then break_l mol2 else [mol2]))
             |> List.map random_flip
             |> mix
  in
  aux mols []
