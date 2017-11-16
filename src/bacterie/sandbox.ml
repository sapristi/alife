(* * this file *)

(* Container for pnets (and later bacteria) *)
(* that will not interact. *)
(* So what we need is a simple map *)

(* * libs *)
open Molecule
open Transition
open Proteine
open Maps
open Petri_net
open Batteries

module MolMap = MakeMolMap
  (struct type t = Molecule.t let compare = Pervasives.compare end)

module SandBox =
  struct

    
    type t =
      {mutable molecules : (PetriNet.t) MolMap.t}
    

    let empty : t = 
      {molecules =  MolMap.empty;}

      
    let get_pnet_from_mol mol (sb : t) = 
      MolMap.find mol sb.molecules

      
    let add_molecule (m : Molecule.t) (sandbox : t) : unit =
      
      if not (MolMap.mem m sandbox.molecules)
      then 
        let p = PetriNet.make_from_mol m in
        sandbox.molecules <- MolMap.add m p sandbox.molecules;;
      
(* *** launch_transition *)
    let launch_transition tid mol sandbox : unit =
      let pnet = MolMap.find mol sandbox.molecules in
      PetriNet.launch_transition_by_id tid pnet;
      PetriNet.update_launchables pnet;;
      
      
    let to_json sandbox =         
      
      let mol_enum = MolMap.enum sandbox.molecules in
      let mol_list = List.of_enum mol_enum in
      
      `Assoc [
         "molecules list",
         `List (List.map
                  (fun (mol, nb) ->
                    `Assoc ["mol", `String mol])
                  mol_list)
     ]
      
  end;;
