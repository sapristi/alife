
(* 1ere version : les transitions sont explictes *)
type temp = int;;

type acid = 
  | Node of temp
  | InputLink of string * temp
  | OutputLink of string * temp;;

type molecule = acid list;;

  
(* Il faut ensuite construire pour chaque transition 
les tableaux des arcs entrants et sortants. *)

(* Putain mais n'importe quoi. On fait tout en un seul passage
sur la molecule, en espérant qu'il n'y ait pas trop de transitions.
On retourne une liste contenant les items (transID, inputLinks, outputLinks)
 *)

let buildTransitions mol = 

  let rec insert_new_input (nodeN : int) (transID : string) (data : temp) transL = 
    match transL with
    | (t, input, output) :: transL' -> 
       if transID = t 
       then (t,  (nodeN, data) :: input, output) :: transL'
       else (t, input, output) :: (insert_new_input nodeN transID data transL')
    | [] -> [transID, [nodeN, data], []]

  and insert_new_output nodeN transID data transL = 
    match transL with
    | (t, input, output) :: transL' -> 
       if transID = t 
       then (t,  input, (nodeN, data) ::  output) :: transL'
       else (t, input, output) :: (insert_new_input nodeN transID data transL')
    | [] -> [transID, [], [nodeN, data]]

  in 
  let rec aux mol nodeN transL = 
    match mol with
    | Node _ :: mol' -> aux mol' (nodeN + 1) transL
    | InputLink (s,d) :: mol' -> aux mol' nodeN (insert_new_input nodeN s d transL)
    | OutputLink (s,d) :: mol' -> aux mol' nodeN (insert_new_output nodeN s d transL)
    | [] -> []

  in aux mol 0 []
;;


let rec buildNodesList mol = 
  match mol with
  | Node d :: mol' -> d :: (buildNodesList mol')
  | _ :: mol' -> buildNodesList mol'
  | [] -> []
;;
     



  
