(* * this file *)
(* Here are defined a particular implementation of the types the different acids a molecule can have. The aim of such a structure is to decorelate the usage and folding of a molecule from a particular implementation. *)

(* * heading *)
(* opening the Molecule module because we generate an instanciated MoleculeManager at the end *)

open Molecule


(* * type definitions *)
(* on va d'abord essayer de définir les types des arcs correctement pour pouvoir travailler sur les transitions plus tranquillement *)

type place_type = 
  | Initial_place
  | Regular_place
  | Handle_place of string
  | Catch_place of string
  | Receive_place of string
  | Release_place
  | Send_place of string
  | Displace_mol_place of bool
      [@@deriving show, yojson]
      
      
type transition_input_type = 
  | Regular_ilink
  | Split_ilink
      [@@deriving show, yojson]

type transition_output_type = 
  | Regular_olink
  | Bind_olink
  | Mol_output_olink
      [@@deriving show, yojson]

(* * MoleculeManager instantiation *)
(* defines the MolTypes struct using the defined types, and then instantiates the MoleculeManager *)

module MolTypes = struct 
    type nodeType = place_type
      [@@deriving show, yojson]
    type transitionInputType = transition_input_type
      [@@deriving show, yojson]
    type transitionOutputType = transition_output_type
      [@@deriving show, yojson]
end

module MyMolecule = MakeMoleculeManager(MolTypes);;
