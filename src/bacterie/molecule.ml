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

   
module type ACID_TYPE = 
sig 
  type acid
         [@@deriving show, yojson]
  type transitionInputFunction
  type transitionOutputFunction
     
  val is_transition_input : acid -> bool
  val is_transition_output : acid -> bool
  val get_transition_label : acid -> string
  val get_transition_input_function : acid -> transitionInputFunction
  val get_transition_output_function : acid -> transitionOutputFunction

end;;


(* * MoleculeManager functor *)
(*   Functor that creates the molecule type and associated functions, given implementations of nodeType, transitionInputType and transitionOutputType *)

module MakeMoleculeManager = 
  functor (AcidT : ACID_TYPE) -> 
struct 
  
(* ** type definitions *)

(* *** molecule type definition *)
  type molecule = AcidT.acid list
                       [@@deriving show, yojson]
                
                
(* *** position type definition *)
(* Correspond à un pointeur vers un des acide de la molécule *)
                
  type position = int
                    [@@deriving show]


(* ***  transition structure type definition *)
(* Transition Input and Output can combine when they share the same identifier, to form a transition. For now, we only put all incomming and outgoing edges into the structure, whose function will be determined later. *)

(* The transition_structure type is made of *)
(*  + a string : the transition identifier *)
(*  + a list of int*AcidT.transitionFunction for the transition inputs : *)
(*    - the int serves as a pointer to the corresponding acid in the molecule *)
(*    - the transitionFunction determines the actions taken by the transition *)
(*  + a list of the same type corresponding to the transition outputs *)


type transition_structure = 
  string * 
    (int * AcidT.transitionFunction ) list * 
      (int * AcidT.transitionFunction) list
                                       [@@deriving show]

(* ** functions definitions *)
(* *** build_transitions function *)

(* This function builds the transitions associated with a molecule. This will be used when folding the molecule to get functional form. *)


(* Il faut ensuite construire pour chaque transition les tableaux des arcs entrants et sortants. On fait tout en un seul passage sur la molecule, en espérant qu'il n'y ait pas trop de transitions. *)
(* On retourne une liste contenant les items (transID, transitionInputs, transitionOutputs) *)

  let build_transitions (mol : molecule) :
        transition_structure list = 
    
    (* insère un arc entrant dans la bonne transition 
       de la liste des transitions *)
    let rec insert_new_input 
              (nodeN :   int) 
              (transID : string) 
              (data :    AcidT.transitionInputFunction) 
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
          (data :    AcidT.transitionOutputFunction)
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
      | a :: mol' ->
         if AcidT.is_transition_input a
         then aux mol' nodeN (insert_new_input nodeN (AcidT.get_transition_label a) (AcidT.get_transition_input_function a) transL)
         else if (AcidT.is_transition_output a)
         then aux mol' nodeN (insert_new_output nodeN (AcidT.get_transition_label a) (AcidT.get_transition_output_function a) transL)
         else transL
      | [] -> transL
           
    in 
    aux mol (-1) []
    
(* *** build_nodes_list function *)
(*     Extrait la liste des noeuds, de la molécule, dans l'ordre rencontré   *)

let rec build_nodes_list (mol : molecule) : MolTypes.nodeType list = 
  match mol with
  | Node d :: mol' -> d :: (build_nodes_list mol')
  | _ :: mol' -> build_nodes_list mol'
  | [] -> []

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
