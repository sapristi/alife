#load "misc_library.cmo"
#load "molecule.cmo"
open Molecule


(* on va d'abord essayer de définir les types des arcs correctement,
pour pouvoir travailler sur les transitions plus tranquillement *)

type place_type = 
  | Regular_place
  | Handle_place of string
  | Catch_place of string
  | Receive_place of string
  | Release_place of string
  | Send_place of string
  | Displace_mol_place of int
;;

type input_link = 
  | Regular_ilink
  | Split_ilink
;;

type output_link = 
  | Regular_olink
  | Bind_olink
  | Mol_output_olink
;;

module MolTypes = struct 
    type nodeType = place_type
    type inputLinkType = input_link
    type outputLinkType = output_link
end;;


module MyMolecule = MolManagement(MolTypes);;
open MyMolecule




type token = moleculeHolder;;
let emptyToken = emptyHolder;;

(*  un holder est soit vide, soit il contient un unique token *)
type token_holder =
  | EmptyHolder
  | OccupiedHolder of token;;



(* fonction qui prends une liste d'arcs entrants 
   et une liste de tokens, et calcule le couple E, mols
   où E est l'énergie totale des tokens, et mols  est 
   la liste des molécules des tokens (qui ont potentiellement
   été coupées
*)
let rec input_transition_function 
    (ill : input_link list)
    (tokens : token list)

    : (moleculeHolder list)
        
 =
  
  match tokens with

  | [] -> []
     
  | m :: tokens' -> 
     if m#is_empty
     
     then 
       input_transition (List.tl ill) tokens'
     
     else 
       match ill with
     
       | []  -> []
	  
       | Regular_ilink ::ill' -> 
	  m ::  input_transition_function ill' tokens'
	  
       | Split_ilink :: ill' -> 
	  let mol1, mol2 = m#cut in
	  mol1 :: mol2 :: input_transition_function ill' tokens'
;;       


(* fonction qui prends une liste d'arcs entrants 
   une energie et une liste de molécukes, 
   et renvoie une liste de tokens
   Chaque token reçoit la moitié de l'énergie restante

   Attention : il faut bien garder la position précédente du token
*)
let rec output_transition_function 
    (oll : output_link list)
    (mols : moleculeHolder list)
    
    : token list 
 =
  
  match oll with
  | Regular_olink :: oll' -> 
     
(* oui c'est plutot très moche comme manière de créer un token vide *)
     emptyToken :: output_transition_function oll'  mols
       
  | Bind_olink :: oll' -> 
     begin
       match mols with
       | m1 ::  m2 :: mols' -> 
	  (m1#insert m2) :: output_transition_function oll' mols
	    
       | m :: [] -> 
	   m  :: output_transition_function oll'  mols
	    
       | [] -> 
	  (emptyHolder) :: output_transition_function oll' mols
     end

  | Mol_output_olink :: oll' -> 
     begin
       match mols with 
       | m :: mols' -> 
	  m  :: output_transition oll'  mols

       | [] -> 
	  emptyToken :: output_transition oll'  mols
     end
  | [] -> []
;;       



(* classe qui gère les places 
   Une place a un type, et peut contenir un jeton

   Initialisé seulement avec un type de place, 
   ne contient pas de jeton au début
*)
type place_id = int;;
class place (placeType : place_type) =
       
object 
  val mutable tokenHolder = EmptyHolder
  val placeType = placeType

  method isEmpty  : bool= tokenHolder = EmptyHolder
  method empty : unit = tokenHolder <- EmptyHolder
  method setToken (t : token) : unit  =
    tokenHolder <- OccupiedHolder t
       
end;;


open Misc_library

(* classe qui gère les transitions 
*)
class transition (places : place array)  (depL : (place_id * input_link) list) (arrL : (place_id * output_link) list) =


  (* renvoie true ssi les places données en argument n'ont pas de jeton *)
  let placesAreFree (places : place array) (to_try : place_id list): bool =
    List.fold_left
      (fun res pId ->
	if places.(pId)#isEmpty
	then res
	else false
      )
      true to_try
  in
  let dp, dl = unzip depL and 
      ap, al = unzip arrL 
  in
  
object
  
  val places = places
  
  val departure_places = dp
  val departure_links = dl
  val arrival_places = ap
  val arrival_links = al

    

  method getArrivalTokens (tokens : token list) : token list = 
    output_transition arrival_links (input_transition departure_links tokens)
  


  (* potentiel des places de départ relativement au type de la transition *)
  method launchable : bool =
    let rec aux l = 
      match l with
      | h :: t -> 
	 not places.(h)#isEmpty && aux t
      | [] -> true
    in 
    (aux departure_places) && placesAreFree places arrival_places
end;;




(* réseau de Petri entier *)
class proteine (mol : molecule) = 
  let raw_transitions = buildTransitions mol
    
  and places_list = 
    List.map 
      (fun x -> new place x)
      (buildNodesList mol)
  
  in
  let places = Array.of_list places_list 
  in
  let transitions = 
    List.map 
      (fun x -> let s, ila, ola = x in
		new transition places ila ola)
      raw_transitions
  in
  
object(self) 
  val mol = mol
  val transitions = Array.of_list transitions
  val places = places
  val mutable launchables = []
    
  method init_launchables = 
    let t_l = ref [] in 
    begin
      for i = 0 to Array.length transitions -1 do
	if transitions.(i)#launchable
	then t_l := transitions.(i) :: !t_l
	else ()
      done;
      launchables <- !t_l;
    end
      

  (* on peut faire beaucoup plus efficace, mais pour l'instant 
     on fait au plus simple *)
  method update_launchables = self#init_launchables
    
  method launch_transition (transition_id : int) = 
    input_tokens = 
    
end;;
