
(* 1ere version : les transitions sont explictes *)
type temp = int;;

type acid = 
  | Node of string * temp
  | Transition of string * temp
  | InputLink of string * temp
  | OutputLink of string * temp;;

type molecule = acid list;;


let rec get_nodes_and_transitions_string mol nodesL transL = 
  match mol with
  | Node (s,_) :: mol' ->       get_nodes_and_transitions_string mol' (s::nodesL) transL
  | Transition (s,_) :: mol' -> get_nodes_and_transitions_string mol' nodesL (s::transL)
  | [] -> nodesL, transL
  | _ :: mol' ->            get_nodes_and_transitions_string mol' nodesL transL
;;

let list_position e l =
  let rec aux l n =  
    match l with
    | f :: l' -> 
       if e = f then n else aux l' n+1
    | [] -> -1
  in aux l 0
;;
  
let rec build_transitions trans_array mol = 
  



let rec get_transitions mol nodes_id trans_id = 
  match mol with
  | InputLink s :: mol' -> 
     


let foldMolecule mol = 
  
