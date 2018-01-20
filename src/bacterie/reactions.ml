(* * reactions *)
(*   Various functions to deal with calculing the next *)
(*   occuring reaction *)


                       
type reaction =
  | Transition of Petri_net.t
  | Collision of (Molecule.t * Molecule.t)
  | Meta of (float * reaction) list
                               [@@deriving show]

(* ** pick reaction *)
(*    Picks the next reaction in a list of reactions. *)
(*    Time is not relevant here *)

let rec pick_reaction (a0 : float) (reac : reaction) : reaction =
  let rec aux (b : float) s (l : (float*reaction) list) :
            (float*reaction) =
    match l with
    | (a, r) :: l' ->
       let s' = a +. s in
       if s' > b then (a,r)
       else aux b s' l'
    | [] -> failwith "pick_reaction @ reactions.ml : can't find reaction"
  in
  match reac with
  | Meta rl ->
     let r = Random.float 1. in
     let bound = r *. a0 in
     let (a0', reac) = aux bound 0. rl in
     pick_reaction a0' reac
  | _ as r -> r


module Reactions = struct

  type collision = float * Molecule.t * Molecule.t
  type transition = float * Molecule.t

  type t =
    { mutable collisions : (collision ref) list;
      mutable total_collisions_rate : float ;
      mutable transitions : (transition ref) list;
      mutable total_transitions_rate : float;
      collision_rate : float;
      transition_rate : float;
    }
    
  (* https://fr.wikipedia.org/wiki/Th%C3%A9orie_des_collisions *)
  let collision_rate mol1 mol2 bact =
    let n1,_,_ = MolMap.find mol1 bact.molecules
    and n2,_,_ = MolMap.find mol2 bact.molecules
    in
    
  let add_collision mol1 mol2 reacs : collision ref =
    collisions := 
