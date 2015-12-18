(* #load "misc_library.ml" *)
open Misc_library


module type MOLECULE_TYPES = 
sig 
  type nodeType
  type inputLinkType
  type outputLinkType
end;;


module MakeMoleculeManager = 
  functor (MolTypes : MOLECULE_TYPES) -> 
struct 
  
  type acid = 
    | Node of MolTypes.nodeType
    | InputLink of string * MolTypes.inputLinkType
    | OutputLink of string * MolTypes.outputLinkType
    | Information of string

  type molecule = acid list
    
  type position = int

  type transition_structure = 
    string * 
      (int * MolTypes.inputLinkType ) list * 
      (int * MolTypes.outputLinkType) list



	  
  
(* Il faut ensuite construire pour chaque transition 
   les tableaux des arcs entrants et sortants. *)

(* Putain mais n'importe quoi. On fait tout en un seul passage
sur la molecule, en espérant qu'il n'y ait pas trop de transitions.
On retourne une liste contenant les items (transID, inputLinks, outputLinks)
 *)

  let build_transitions (mol : molecule) :
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
      | Information _ :: mol' -> aux mol' nodeN transL
      | [] -> []
	 
    in 
    aux mol 0 []
    
      
(* Construit la liste des noeuds, dans l'ordre rencontré. *)
  let rec build_nodes_list (mol : molecule) : MolTypes.nodeType list = 
    match mol with
    | Node d :: mol' -> d :: (build_nodes_list mol')
    | _ :: mol' -> build_nodes_list mol'
    | [] -> []
  


  module MoleculeHolder =
  struct 
    type t = molecule * int
	  
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
  



  
