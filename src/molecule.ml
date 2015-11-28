(* #load "misc_library.ml" *)
open Misc_library


module type MOLECULE_TYPES = 
sig 
  type nodeType
  type inputLinkType
  type outputLinkType
end;;


module MolManagement = 
  functor (MolTypes : MOLECULE_TYPES) -> 
struct 
  
  type acid = 
    | Node of MolTypes.nodeType
    | InputLink of string * MolTypes.inputLinkType
    | OutputLink of string * MolTypes.outputLinkType

  type molecule = acid list
    
  type position = int

  type transition_structure = 
    string * 
      (int * MolTypes.inputLinkType ) list * 
      (int * MolTypes.outputLinkType) list
      
(* Normalement on se sert pas de ce truc

  type transition_with_array = 
    string * 
      (int * MolTypes.inputLinkType ) array * 
      (int * MolTypes.outputLinkType) array
*)
  
(* Il faut ensuite construire pour chaque transition 
   les tableaux des arcs entrants et sortants. *)

(* Putain mais n'importe quoi. On fait tout en un seul passage
sur la molecule, en espérant qu'il n'y ait pas trop de transitions.
On retourne une liste contenant les items (transID, inputLinks, outputLinks)
 *)

  let buildTransitions (mol : molecule) :
      transition_structure list = 
    
    (* insère un arc entrant dans la bonne transition 
       de la liste des transitions *)
    let rec insert_new_input 
	(nodeN :   int) 
	(transID : string) 
	(data :    MolTypes.inputLinkType) 
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
	(data :    MolTypes.outputLinkType) 
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
      | InputLink (s,d) :: mol' -> aux mol' nodeN (insert_new_input nodeN s d transL)
      | OutputLink (s,d) :: mol' -> aux mol' nodeN (insert_new_output nodeN s d transL)
      | [] -> []
	 
    in 
    aux mol 0 []
    
      
(* Construit la liste des noeuds, dans l'ordre rencontré. *)
  let rec buildNodesList (mol : molecule) : MolTypes.nodeType list = 
    match mol with
    | Node d :: mol' -> d :: (buildNodesList mol')
    | _ :: mol' -> buildNodesList mol'
    | [] -> []
  


(* Classe qui permet de gérer les objets qui tiennent une molécule 
   Lorsqu'une molécule est présente, on peut la couper (à la position 
   en cours dans le MolHolder), ou de la lier avec une autre molécule
   lorsque cette position est finale *)
  class moleculeHolder (initMol : molecule) (initPos : position) =
    
  object(self)
    val mol = initMol
    val mutable pos = initPos

    method get_molecule : molecule = 
      mol

    method is_empty : bool = 
      mol = []

    method move_forward : unit = 
      if pos < self#mol_length -1 
      then pos <- pos + 1
	
    method move_backward : unit =
      if pos > 0
      then pos <- pos - 1

    method mol_length : int = 
      List.length mol

    (* Coupe la molécule à la position en cours. 
       Renvoie deux molécules
       Il faudrait moralement supprimer la molécule quand on a fini  *)
    method cut : (moleculeHolder * moleculeHolder) = 
      let m1, m2 = Misc_library.cut_list mol pos in 
      new moleculeHolder m1 (List.length m1 - 1), new moleculeHolder m2 0

    (* insère la molécule m2 dans la molécule en cours
       Remplace bind, parce que ça peut servir à ça et c'est 
       plus facile à implémenter proprement
    *)
    method insert (m2 : moleculeHolder) : moleculeHolder = 
      new moleculeHolder 
	(Misc_library.insert mol pos m2#get_molecule)
	(pos + m2#mol_length)
	
  end;;

  let emptyHolder = new moleculeHolder [] 0;;
end;;
  



  
