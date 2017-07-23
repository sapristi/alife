
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
      [@@deriving show, yojson]
      
      
type input_link = 
  | Regular_ilink
  | Split_ilink
      [@@deriving show, yojson]

type output_link = 
  | Regular_olink
  | Bind_olink
  | Mol_output_olink
      [@@deriving show, yojson]


module MolTypes = struct 
    type nodeType = place_type
      [@@deriving show, yojson]
    type inputLinkType = input_link
      [@@deriving show, yojson]
    type outputLinkType = output_link
      [@@deriving show, yojson]
end

module MyMolecule = MakeMoleculeManager(MolTypes);;
