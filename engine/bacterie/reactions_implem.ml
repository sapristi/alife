(** Effects

    This file contains the functions used by the reactions to define what
    happens when the reaction is triggered.
*)

open Local_libs
open Misc_library
open Easy_logging_yojson
open Base_chemistry
open CCList

let logger = Logging.get_logger "Yaac.Bact.Reacs_effects"


(** asymetric_grab: one pnet grabs something *)
let asymetric_grab randstate mol pnet =
  let grabs = Petri_net.get_possible_mol_grabs mol pnet in
  if not (grabs = []) then
    let grab, pid = Random_s.pick_from_list randstate grabs in
    match grab with pos -> Petri_net.grab mol pos pid pnet
  else false

(** break function: breaks a mol in two pieces *)
let break randstate mol =
  let n = String.length mol in
  let b = 1 + Random_s.int randstate (n - 1) in
  (String.sub mol 0 b, String.sub mol b (n - b))

let break_l randstate mol =
  logger#debug "Breaking %s" mol;

  if String.length mol < 2 then [ mol ]
  else
    let n = String.length mol in
    let b = 1 + Random_s.int randstate (n - 1) in
    [ String.sub mol 0 b; String.sub mol b (n - b) ]

(** collision
 The result of a collision is a reorganisation of
 both colliding molecules. Each operation happens
 with a configurable probability:
  - each colliding molecule can break in two pieces
  - each resulting piece can be flipped
  - the pieces will then form new molecules
    by concatenation. *)

let rec random_flip randstate m =
  if Random_s.bernouil_f randstate 0.5 then
    let l = String.length m in
    String.init l (fun i -> m.[l - i - 1])
  else m

let collide randstate mol1 mol2 =
  logger#debug "Colliding %s and %s" mol1 mol2;

  (*
  let rec aux l res =
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
*)
  let rec aux l res =
    match l with
    | [] -> res
    | h :: [] -> h :: res
    | h :: h' :: t ->
        if Random_s.bernouil_f randstate 0.8 then aux (h' :: t) (h :: res)
        else aux t ((h ^ h') :: res)
  in

  let l1 =
    if Random_s.bernouil_f randstate 0.5 then break_l randstate mol1
    else [ mol1 ]
  and l2 =
    if Random_s.bernouil_f randstate 0.5 then break_l randstate mol2
    else [ mol2 ]
  in
  let l = l1 @ l2 in
 
  logger#debug "Breaked into %s"
    (CCFormat.sprintf "%a" (CCList.pp CCFormat.string) l);
  let fl = List.map (random_flip randstate) l in
  logger#debug "Flipped into %s"
    (CCFormat.sprintf "%a" (CCList.pp CCFormat.string) fl);
  let mols = Random_s.shuffle_list randstate fl in
  logger#debug "Shuffled into %s"
    (CCFormat.sprintf "%a" (CCList.pp CCFormat.string) mols);

  (*
  let mols = ((if bernouil_f 0.5
              then break_l mol1 else [mol1])
             @ (if bernouil_f 0.5
                then break_l mol2 else [mol2]))
             |> List.map random_flip
             |> mix *)
  aux mols []
