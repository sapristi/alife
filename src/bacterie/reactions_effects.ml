open Local_libs
open Misc_library

(* * File overview *)

(* This file contains the functions used by the reactions to define what  *)
(* happens when the reaction is triggered.  *)
(* The functions are externalised in this file to allow easy configuration *)
(* of implementation details *)

(* * asymetric_grab auxiliary function *)
(*  Why is it not in the functor ?  *)

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


let break mol =
  Molecule.break mol
