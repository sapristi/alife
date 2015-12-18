
open Molecule_module


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
;;

type input_link = 
  | Regular_ilink
  | Split_ilink
;;

type output_link = 
  | Regular_olink
  | Bind_olink
  | Mol_output_olink
;;

module MolTypes = struct 
    type nodeType = place_type
    type inputLinkType = input_link
    type outputLinkType = output_link
end;;


module MyMolecule = MakeMoleculeManager(MolTypes);;
