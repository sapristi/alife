(* * this file *)
(* Here are defined a particular implementation of the types the different acids a molecule can have. The aim of such a structure is to decorelate the usage and folding of a molecule from a particular implementation. *)

(* * heading *)
(* opening the Molecule module because we generate an instanciated MoleculeManager at the end *)

open Molecule


(* * type definitions *)

(* ** description générale *)
(*    :in-progress: *)
(*    Implémentation des types différents acides. Voilà en gros l'organisation : *)
(*   + place : aucune action *)
(*   + transition : agit sur la molécule contenue dans un token *)
(*     - regular : rien de particulier *)
(*     - split : coupe une molécule en 2 (seulement transition_input) *)
(*     - bind : insère une molécule dans une autre (seulement transition_output) *)
(*   + extension : autres ? *)
(*     - handle : poignée pour attraper cette molécule *)
(*       problème : il faudrait pouvoir attrapper la molécule à n'importe quel acide ? ou alors on attrappe la poignée directement et pas la place associée *)
(*     - catch : permet d'attraper une molécule. *)
(*       Est ce qu'il y a une condition d'activation, par exemple un token vide (qui contiendrait ensuite la molécule) ? *)
(*     - release : lache la molécule attachée *)
(*     - move : déplace le point de contact de la molécule *)
(*     - send : envoie un message *)
(*     - receive : receives a message *)

(*   Questions : est-ce qu'on met l'action move sur les liens ou en extension ? dans les liens c'est plus cohérent, mais dans les extensions ça permet d'en mettre plusiers à la suite. Par contre, à quel moment est-ce qu'on déclenche l'effet de bord ? En recevant le token d'une transition.  Mais du coup pour l'action release, il faudrait aussi la mettre sur les places, puisqu'on agit aussi à l'extérieur du token. Du coup pour l'instant on va mettre à la fois move et release dans les extensions, avec un système pour appliquer les effets des extensions quand on reçoit un token. *)

(* ** place *)
(* Aucun effet de bord pour l'instant *)
type place_type = 
  | Regular_place
      [@@deriving show, yojson]
      

(* ** transition_input *)
type transition_input_type = 
  | Regular_ilink
  | Split_ilink
      [@@deriving show, yojson]

(* ** transition_output *)
type transition_output_type = 
  | Regular_olink
  | Bind_olink
      [@@deriving show, yojson]

(* ** extension *)
type extension_type =
  | Handle_ext of string
  | Catch_ext of string
  | Receive_ext of string
  | Release_ext
  | Move_ext of bool
  | Send_ext of string
  | Displace_mol_ext of bool
      [@@deriving show, yojson]

(* * MoleculeManager instantiation *)
(* defines the MolTypes struct using the defined types, and then instantiates the MoleculeManager *)

module AcidTypes = struct 
  type placeType = place_type
                     [@@deriving show, yojson]
  type transitionInputType = transition_input_type
                               [@@deriving show, yojson]
  type transitionOutputType = transition_output_type
                                [@@deriving show, yojson]
  type extensionType = extension_type
                          [@@deriving show, yojson]
                              
end

module MyMolecule = MakeMoleculeManager(AcidTypes);;
