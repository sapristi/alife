

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
