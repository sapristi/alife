
module type MOLECULE_TYPES = 
sig 
  type nodeType
  type inputLinkType
  type outputLinkType
end;;


module MolFolcding = 
  functor (MolTypes : MOLECULE_TYPES) -> 
struct 
  
  type acid = 
    | Node of MolTypes.nodeType
    | InputLink of string * MolTypes.inputLinkType
    | OutputLink of string * MolTypes.outputLinkType

  type molecule = acid list
    
  type transition_with_lists = 
    string * 
      (int * MolTypes.inputLinkType ) list * 
      (int * MolTypes.outputLinkType) list
      
  type transition = 
    string * 
      (int * MolTypes.inputLinkType ) array * 
      (int * MolTypes.outputLinkType) array
    
(* Il faut ensuite construire pour chaque transition 
   les tableaux des arcs entrants et sortants. *)

(* Putain mais n'importe quoi. On fait tout en un seul passage
sur la molecule, en espérant qu'il n'y ait pas trop de transitions.
On retourne une liste contenant les items (transID, inputLinks, outputLinks)
 *)

  let buildTransitions (mol : molecule) :
      transition list = 
    
    (* insère un arc entrant dans la bonne transition 
       de la liste des transitions *)
    let rec insert_new_input 
	(nodeN :   int) 
	(transID : string) 
	(data :    MolTypes.inputLinkType) 
	(transL :  transition_with_lists list) : 
	
	transition_with_lists list =
      
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
	(transL :  transition_with_lists list) :

	transition_with_lists list =  

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
	(transL : transition_with_lists list) :

	transition_with_lists list = 
 
      match mol with
      | Node _ :: mol' -> aux mol' (nodeN + 1) transL
      | InputLink (s,d) :: mol' -> aux mol' nodeN (insert_new_input nodeN s d transL)
      | OutputLink (s,d) :: mol' -> aux mol' nodeN (insert_new_output nodeN s d transL)
      | [] -> []
	 
    in 

    List.map (fun x -> 
      let (y, l1, l2) = x in
      (y, Array.of_list l1, Array.of_list l2))
      (aux mol 0 [])
    
      

  let rec buildNodesList (mol : molecule) : MolTypes.nodeType list = 
    match mol with
    | Node d :: mol' -> d :: (buildNodesList mol')
    | _ :: mol' -> buildNodesList mol'
    | [] -> []
  

end;;
  



  
