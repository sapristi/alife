(* * this file *)
(* Here are defined a particular implementation of the types the different acids a molecule can have. The aim of such a structure is to decorelate the usage and folding of a molecule from a particular implementation. *)

(* * heading *)
(* opening the Molecule module because we generate an instanciated MoleculeManager at the end *)

open Molecule


(* * type definitions *)

(* On définit d'abord les types de transition, pour les inclure ensuite dans les types d'acides. *)
(* *unfinished* Les types ne sont pas complètement implémentés pour faciliter l'écriture du code, donc pour l'instant les fonctions de transition ne sont pas finalisables *)

(* ** transition_input *)
(* Can be either : *)
(*  + Regular : nothing happens *)
(*  + Split : cuts the holded molecule *)
(*  + Move : changes the position at which the bound molecule is attached *)

type transition_input_type = 
  | Regular_transi
  | Split_transi
  | Catch_transi
  | Move_transi 
      [@@deriving show, yojson]


(* ** transition_output *)
(* Can be either : *)
(*  + Regular : nothing happens *)
(*  + Bind : inserts a molecule into another one *)
(*  + Release : releases the bound molecule *)
(*  + Move : changes the position at which the bound molecule is attached *)
(*  + Filter : accepts a token only on certain conditions *)


type transition_output_type = 
  | Regular_transo
  | Bind_transo
  | Realease_transo
  | Move_transo
  | Filter_transo
      [@@deriving show, yojson]

(* ** acid *)
(* Can be either : *)
(*  + Initial : contains a token at the proteine creation *)
(*  + Regular : nothing particular *)
(*  + Handle : allows other molecule to grab it at this position *)
(*  + Receive : creates token when receiving a message *)
(*  + Send : sends a message when a token arrives *)
(*  + TransI : transition input *)
(*  + TransO : transition output *)
(*  + Information : contains a bit of information *)

type acid_type = 
  | Initial_place
  | Regular_place
  | Handle_place of string
  | Receive_place of string
  | Send_place of string
  | TransI_place of transition_input_type
  | TransO_place of transition_output_type
  | Information_place of string
      [@@deriving show, yojson]

(* * MoleculeManager instantiation *)
(* defines the MolTypes struct using the defined types, and then instantiates the MoleculeManager *)

module MolTypes = struct 
    type nodeType = acid_type
      [@@deriving show, yojson]
    type transitionInputType = transition_input_type
      [@@deriving show, yojson]
    type transitionOutputType = transition_output_type
      [@@deriving show, yojson]
end

module MyMolecule = MakeMoleculeManager(MolTypes);;
