(* * this file *)

(* molecule.ml defines the basic properties of a molecule, some functions to help build a proteine out of it and a module to help it get managed by a protein (i.e. simulate chemical reactions *)



(* * preamble : load libraries *)

(* next lines are used when compiling in a ocaml toplevel *)
(* #directory "../../_build/src/libs" *)
(* #load "misc_library.ml" *)

open Misc_library

(* * defining abstract types for acids *)

(*   On définit trois types abstraits pour les acides. *)
(*   Les types sont implémentés dans le fichier custom_types.ml *)

   
module type ACID_TYPES = 
  sig 
    type placeType
           [@@deriving show, yojson]
    type extensionType
           [@@deriving show, yojson]
    type transitionOutputType
           [@@deriving show, yojson]
    type transitionInputType
           [@@deriving show, yojson]
       
  end;;


(* * MoleculeManager functor *)
(*   Functor that creates the molecule type and associated functions, given implementations of placeType, transitionInputType and transitionOutputType *)

module MakeMoleculeManager = 
  functor (AcidTypes : ACID_TYPES) -> 
struct 
  
(* ** type definitions *)
(* *** acid type definition *)
(* We define how the abstract types get combined to form functional types to eventually create a proteine (petri net) *)
(*  + Node : used as a token placeholder in the petri net *)
(*  + TransitionInput :  an incomming edge into a transition of the petri net *)
(*  + a transition output : an outgoing edge into a transition of the petri net *)
(*  + a piece of information : ???? *)
  
  type acid = 
    | Node of AcidTypes.placeType
    | TransitionInput of string * AcidTypes.transitionInputType
    | TransitionOutput of string * AcidTypes.transitionOutputType
    | Extension of AcidTypes.extensionType
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
    (int * AcidTypes.transitionInputType ) list * 
      (int * AcidTypes.transitionOutputType) list
                                             [@@deriving show]

(* *** place extensions definition *)

  type place_extensions =
    AcidTypes.extensionType list
    
(* ** functions definitions *)
(* *** build_transitions function *)

(* This function builds the transitions associated with a molecule. This will be used when folding the molecule to get functional form. *)
(* On retourne une liste contenant les items (transID, transitionInputs, transitionOutputs) *)
(* Algo : on parcourt les acides de la molécule, en gardant en mémoire l'id du dernier nœud visité. Si on tombe sur un acide contenant une transition, on parcourt la liste des transitions déjà créées pour voir si des transitions avec la même id ont déjà été traitées, auquel cas on ajoute cette transition à la transition_structure correspondante, et sinon on créée une nouvelle transition_structure *)

(* Idées pour améliorer l'algo :  *)
(*  - utiliser une table d'associations  (pour accélerer ?)  *)

let build_transitions (mol : molecule) :
      transition_structure list = 
  
  (* insère un arc entrant dans la bonne transition 
     de la liste des transitions *)
  let rec insert_new_input 
            (nodeN :   int) 
            (transID : string) 
            (data :    AcidTypes.transitionInputType) 
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
        (data :    AcidTypes.transitionOutputType) 
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

  let rec build_nodes_list (mol : molecule) : AcidTypes.placeType list = 
    match mol with
    | Node d :: mol' -> d :: (build_nodes_list mol')
    | _ :: mol' -> build_nodes_list mol'
    | [] -> []

(* *** build_nodes_list_with_exts function *)
(* Construit la liste des nœuds avec les extensions associéeNote : l'ordre des liste sera dans l'ordre inverse de l'ordre initial de la molécule *)

  let build_nodes_list_with_exts (mol : molecule) :
        (AcidTypes.placeType * (AcidTypes.extensionType list)) list =
    
    let rec aux mol res = 
      match mol with
      | Node n :: mol' -> aux mol' ((n, []) ::res)
      | Extension e :: mol' ->
         begin
           match res with
           | [] -> aux mol' res
           | (n, ext_l) :: res' ->
              aux mol' ((n, e :: ext_l) :: res)
         end
      | _ :: mol' -> aux mol' res
      | [] -> res
    in
    aux mol []
    
(* ** the MoleculeHolder module *)
(* Module used to manage a molecule attached at some position to another molecule : defines functions to change the position of attach, cut the molecule, and insert another molecule at position           *)
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
    end
    
    
end;;
  
