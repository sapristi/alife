(* * this file *)

(* molecule.ml defines the basic properties of a molecule, some functions to help build a proteine out of it and a module to help it get managed by a protein (i.e. simulate chemical reactions *)

(* * preamble : load libraries *)

(* next lines are used when compiling in a ocaml toplevel *)
(* #directory "../../_build/src/libs" *)
(* #load "misc_library.ml" *)

open Misc_library

(* * defining types for acids *)

   
(* ** description générale :in_progress: *)
(*    Implémentation des types différents acides. Voilà en gros l'organisation : *)
(*   + place : aucune fonctionalité *)
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

   

module AcidTypes =
  struct
    
(* ** place *)    
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
(* Types used by the extensions. Usefull to use custom types for easier potential changes later on.  *)
    type handle_id = string
                       [@@deriving show, yojson]
    type catch_pattern = string
                           [@@deriving show, yojson]
    type receive_pattern = string
                             [@@deriving show, yojson]
    type msg_format = string
                        [@@deriving show, yojson]
                    
    type extension_type =
      | Handle_ext of handle_id
      | Catch_ext of catch_pattern
      | Receive_msg_ext of msg_format
      | Release_ext
      | Move_ext of bool
      | Send_msg_ext of msg_format
      | Displace_mol_ext of bool
      | Init_with_token
[@@deriving show, yojson]
  end;;
  

(* * MoleculeManager functor *)
(*   Functor that creates the molecule type and associated functions, given implementations of place_type, transition_input_type and transition_output_type *)

module Molecule = 
  struct 
    
(* ** type definitions *)
(* *** acid type definition *)
(* We define how the abstract types get combined to form functional types to eventually create a proteine (petri net) *)
(*  + Node : used as a token placeholder in the petri net *)
(*  + TransitionInput :  an incomming edge into a transition of the petri net *)
(*  + a transition output : an outgoing edge into a transition of the petri net *)
(*  + a piece of information : ???? *)
  
  type acid = 
    | Node of AcidTypes.place_type
    | TransitionInput of string * AcidTypes.transition_input_type
    | TransitionOutput of string * AcidTypes.transition_output_type
    | Extension of AcidTypes.extension_type
                     [@@deriving show, yojson]
                 
                   
  type molecule = acid list
                       [@@deriving show, yojson]
                
                
(* *** position type definition *)
(* Correspond à un pointeur vers un des acide de la molécule *)
                
  type position = int
                    [@@deriving show]


(* *** transition structure type definition *)

(* Structure utilisée pour stoquer une transition.  *)
(* Triplet contenant : *)
(*  - une string, l'identifiant de la transition *)
(*  - une liste int*transInput*Type, dont chaque item contient  *)
(*  l'entier correspondant au nœud d'où part la transistion,  *)
(*  et le type de la transition *)
(*  - de même pour les arcs sortants *)
                
  type transition_structure = 
    string * 
      (int * AcidTypes.transition_input_type ) list * 
        (int * AcidTypes.transition_output_type) list
                                               [@@deriving show]
    
(* *** place extensions definition *)

  type place_extensions =
    AcidTypes.extension_type list
    
(* ** functions definitions *)
(* *** build_transitions function *)

(* This function builds the transitions associated with a molecule. This will be used when folding the molecule to get functional form. *)
(* On retourne une liste contenant les items (transID, transitionInputs, transitionOutputs) *)
(* Algo : on parcourt les acides de la molécule, en gardant en mémoire l'id du dernier nœud visité. Si on tombe sur un acide contenant une transition, on parcourt la liste des transitions déjà créées pour voir si des transitions avec la même id ont déjà été traitées, auquel cas on ajoute cette transition à la transition_structure correspondante, et sinon on créée une nouvelle transition_structure *)

(* Idées pour améliorer l'algo : *)
(*   - utiliser une table d'associations  (pour accélerer ?) *)
(*   - TODO : faire attention si plusieurs arcs entrants ou sortant correspondent au même nœud et à la même transition, auquel cas ça buggerait *)

let build_transitions (mol : molecule) :
      transition_structure list = 
  
  (* insère un arc entrant dans la bonne transition 
     de la liste des transitions *)
  let rec insert_new_input 
            (nodeN :   int) 
            (transID : string) 
            (data :    AcidTypes.transition_input_type) 
            (transL :  transition_structure list) : 
            
            transition_structure list =
    
    match transL with
    | (t, input, output) :: transL' -> 
       if transID = t 
       then (t,  (nodeN, data) :: input, output) :: transL'
       else (t, input, output) :: (insert_new_input nodeN transID data transL')
    | [] -> [transID, [nodeN, data], []]
          
          
  (* insère un arc sortant dans la bonne transition 
     de la liste des transitions *)
  and insert_new_output 
        (nodeN :   int) 
        (transID : string)
        (data :    AcidTypes.transition_output_type) 
        (transL :  transition_structure list) :
        
        transition_structure list =  
    
    match transL with
    | (t, input, output) :: transL' -> 
       if transID = t 
       then (t,  input, (nodeN, data) ::  output) :: transL'
       else (t, input, output) :: (insert_new_output nodeN transID data transL')
    | [] -> [transID, [], [nodeN, data]]
          
  in 
  let rec aux 
            (mol :    molecule)
            (nodeN :  int) 
            (transL : transition_structure list) :
            
            transition_structure list = 
    
    match mol with
    | Node _ :: mol' -> aux mol' (nodeN + 1) transL
    | TransitionInput (s,d) :: mol' -> aux mol' nodeN (insert_new_input nodeN s d transL)
    | TransitionOutput (s,d) :: mol' -> aux mol' nodeN (insert_new_output nodeN s d transL)
    | Extension _ :: mol' -> aux mol' nodeN transL
    | [] -> transL
     
  in 
  aux mol (-1) []
  
(* *** build_nodes_list function :deprecated: *)
(*     Extrait la liste des noeuds, de la molécule, dans l'ordre rencontré   *)

  let rec build_nodes_list (mol : molecule) : AcidTypes.place_type list = 
    match mol with
    | Node d :: mol' -> d :: (build_nodes_list mol')
    | _ :: mol' -> build_nodes_list mol'
    | [] -> []

(* *** build_nodes_list_with_exts function *)
(* Construit la liste des nœuds avec les extensions associéeNote : l'ordre des liste sera dans l'ordre inverse de l'ordre initial de la molécule *)

  let build_nodes_list_with_exts (mol : molecule) :
        (AcidTypes.place_type * (AcidTypes.extension_type list)) list =
    
    let rec aux mol res = 
      match mol with
      | Node n :: mol' -> aux mol' ((n, []) :: res)
      | Extension e :: mol' ->
         begin
           match res with
           | [] -> aux mol' res
           | (n, ext_l) :: res' ->
              aux mol' ((n, e :: ext_l) :: res')
         end
      | _ :: mol' -> aux mol' res
      | [] -> res
    in
    aux mol []
    

(* *** get_handles : *)
(* Given a molecule, returns a list of tuples (handle_position, handle_id) *)

  let get_handles (mol : molecule) : (int * AcidTypes.handle_id) list =
    let rec aux mol n =
      match mol with
      | Extension ext :: mol' ->
         begin
           match ext with
           | AcidTypes.Handle_ext hid -> (n, hid) :: aux mol' (n+1)
           | _ -> aux  mol' (n+1)
         end
      | _ :: mol' -> aux mol' (n+1)
      | [] -> []
    in
    aux mol 0
end;;
    

(* * the MoleculeHolder module *)

(* Module used to manage a molecule attached at some position to another molecule : defines functions to change the position of attach, cut the molecule, and insert another molecule at position *)

open Molecule
module MoleculeHolder =
  struct 
    type t = molecule * int
                          [@@deriving show, yojson]
           
    let is_empty (h : t) : bool = 
      let m,p = h in m = []
                   
    let empty = ([],0)
              
    let make (mol : molecule) : t = mol,0
                                  
    let make_at_pos (mol : molecule) (pos : int) : t = mol,pos
                                                     
    let get_molecule (h : t) : molecule =
      let m,_ = h in m
                   
    let move_forward (h : t) : t =
      let m,p = h in  m, p+1
                    
    let move_backward (h : t) : t =
      let m,p = h in  m, p-1
                    
    let get_mol_length (h : t) : int = 
      let m,p = h in  List.length m
                    
    let get_postion (h : t) : int = 
      let m,p = h in p
                   
    let cut (h : t) : t*t =
      let mol, pos = h in 
      let m1, m2 = Misc_library.cut_list mol pos in
      (m1,pos), (m2, 0)
      
    let insert (h1 : t) (h2 : t) : t =
      match h1, h2 with
      |  (m1, p1), (m2, p2) ->
          (Misc_library.insert m1 p1 m2), 0
  end;;
