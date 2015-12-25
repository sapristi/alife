
open Molecule


(* on va d'abord essayer de définir les types des arcs correctement,
pour pouvoir travailler sur les transitions plus tranquillement *)

type place_type = 
  | Initial_place
  | Regular_place
  | Handle_place of string
  | Catch_place of string
  | Receive_place of string
  | Release_place
  | Send_place of string
  | Displace_mol_place of bool
      [@@deriving show]
      
      
type input_link = 
  | Regular_ilink
  | Split_ilink
      [@@deriving show]

type output_link = 
  | Regular_olink
  | Bind_olink
  | Mol_output_olink
      [@@deriving show]


module MolTypes = struct 
    type nodeType = place_type
      [@@deriving show]
    type inputLinkType = input_link
      [@@deriving show]
    type outputLinkType = output_link
      [@@deriving show]

      (*
    let nodeType_to_string nt =
      match nt with
      | Initial_place -> "Initial_place"
      | Regular_place -> "Regular_place"
      | Handle_place s -> "Handle ("^s^") place"
      | Catch_place s -> "Catch ("^s^") place"
      | Receive_place s -> "Receive ("^s^") place"
      | Release_place -> "Release place"
      | Send_place s -> "Send ("^s^") place"
      | Displace_mol_place b -> "Displace_mol place"

    let inputLinkType_to_string ilt =
      match ilt with
      | Regular_ilink -> "Regular_ilink"
      | Split_ilink -> "Split_ilink"

    let outputLinkType_to_string olt =
      match olt with
      | Regular_olink -> "Regular_olink"
      | Bind_olink -> "Bind_olink"
      | Mol_output_olink -> "Mol_output_olink"
      *)
end

module MyMolecule = MakeMoleculeManager(MolTypes);;
