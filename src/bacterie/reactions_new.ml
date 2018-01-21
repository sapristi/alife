

type mol_data = Molecule.t * int ref * Petri_net.t option ref
[@@deriving show]
(* TODO : manque self_collision 
avec taux de réaction approprié *)
type collision = {
    mutable rate : float;
    mol1 : mol_data;
    mol2 : mol_data;
  }
                   [@@deriving show]
type transition = {
    mutable rate : float;
    mol : mol_data;
  }
                    [@@deriving show]

type reaction =
  | Transition of transition ref
  | Collision of collision ref  
type t =
  { mutable collisions : collision ref list;
    mutable total_collisions_rate : float ;
    mutable transitions : transition ref list;
    mutable total_transitions_rate : float;
    raw_collision_rate : float;
    raw_transition_rate : float;
  }
    [@@deriving show]

let make_new () : t =
  {
    collisions = [];
    total_collisions_rate = 0.;
    transitions = [];
    total_transitions_rate = 0.;
    raw_collision_rate = 1.;
    raw_transition_rate = 10.;
  }
  
(* **** collision *)
(*     The collision probability between two molecules is *)
(*     the product of their quantities. *)
(*     We might need to add other parameters, such as *)
(*     the volume of the container, and use a float constant *)
(*     to avoid integer overflow. *)
(*     We here calculate each collision probability, *)
(*     and the sum of it. *)
(*     WARNING : possible integer overflow *) 
(* https://fr.wikipedia.org/wiki/Th%C3%A9orie_des_collisions *)
let collision_rate mol1 mol2 reacs=
  match mol1, mol2 with
  | (_, rn1, _), (_, rn2, _) ->
     (float_of_int !rn1 *. float_of_int !rn2 *. reacs.raw_collision_rate)
    
let transition_rate mol reacs =
  match mol with
    | (_, rn, _) -> float_of_int !rn *. reacs.raw_transition_rate
                  
let add_collision mol1 mol2 reacs : collision ref=
  let c = {
      rate = collision_rate mol1 mol2 reacs;
      mol1 = mol1;
      mol2 = mol2;
    }
  in
  print_endline (show_collision c);
  let rc = ref c in
  reacs.collisions <- rc :: reacs.collisions;
  reacs.total_collisions_rate <-
    c.rate +. reacs.total_collisions_rate;
  rc
  
let update_collision_rate (rc : collision ref) reacs =
  let old_rate  = !rc.rate 
  and new_rate = collision_rate (!rc).mol1 (!rc).mol2 reacs
  in
  !rc.rate <- new_rate;
  reacs.total_collisions_rate <-
    reacs.total_collisions_rate -. old_rate +. new_rate

let add_transition mol reacs : transition ref =
  let t = {
      rate = transition_rate mol reacs;
      mol = mol;
    }
  in
  let rt = ref t in
  reacs.transitions <- rt :: reacs.transitions;
  reacs.total_transitions_rate <-
    t.rate +. reacs.total_transitions_rate;
  rt
  
let update_transition_rate (rt : transition ref) reacs =
  let old_rate = (!rt).rate
  and new_rate = transition_rate (!rt).mol reacs in
  !rt.rate <- new_rate;
  reacs.total_transitions_rate <-
    reacs.total_transitions_rate -. old_rate +. new_rate       
    
let rec aux
          (b : float) (c : float)
          (r_access : 'a -> float)
          (l : 'a list)  = 
  match l with
  | h::t ->
     let c' = c +. (r_access h) in
     if c' > b then h
     else aux b c' r_access t
  | [] -> failwith "pick_reaction @ reactions.ml : can't find reaction"
        
let pick_next_reaction reacs =
  print_endline (show reacs);

  
  let a0 = reacs.total_collisions_rate +. reacs.total_transitions_rate
  and r = Random.float 1. in
  let bound = r *. a0 in
  if bound < reacs.total_collisions_rate
  then
    let a0 = reacs.total_collisions_rate
    and r = Random.float 1. in
    let bound = r *. a0 in
    Collision
      (aux bound 0.
           (fun (col : collision ref) -> (!col).rate)
           reacs.collisions)
  else  
    let a0 = reacs.total_transitions_rate
    and r = Random.float 1. in
    let bound = r *. a0 in
    Transition
      (aux bound 0.
           (fun (tr : transition ref) -> (!tr).rate)
           reacs.transitions)
