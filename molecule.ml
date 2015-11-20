
(* 1ere version : les transitions sont explictes *)
type temp = int;;

type acid = 
  | Node of string * temp
  | Transition of string * temp
  | InputLink of string * temp
  | OutputLink of string * temp;;

type molecule = acid list;;

(* On commence par extraire les labels des noeuds et des transitions, 
qu'on met dans deux listes qui vont bien.
On associe en même temps les arcs avec leurs noeuds :
une liste d'arcs par noeuds.

Mais que fait on si plusieurs noeuds ou transitions partagent le 
même label ??? :(




 *)
let rec get_nodes_and_transitions_string mol nodesL transL = 
  match mol with
  | Node (s,_) :: mol' ->       get_nodes_and_transitions_string mol' (s::nodesL) transL
  | Transition (s,_) :: mol' -> get_nodes_and_transitions_string mol' nodesL (s::transL)
  | [] -> nodesL, transL
  | _ :: mol' ->            get_nodes_and_transitions_string mol' nodesL transL
;;


(* retourne la premier position de l'item recherché 
(ou -1 s'il n'est pas là *)
let list_position e l =
  let rec aux l n =  
    match l with
    | f :: l' -> 
       if e = f then n else aux l' n+1
    | [] -> -1
  in aux l 0
;;
  
(* Il faut ensuite construire pour chaque transition 
les tableaux des arcs entrants et sortants.
On construit d'abord des listes.
*) 
let rec build_transitions trans_array mol = 
  match mol with
  | InputLink (s,t) -> 



let rec get_transitions mol nodes_id trans_id = 
  match mol with
  | InputLink s :: mol' -> 
     


let foldMolecule mol = 
  
