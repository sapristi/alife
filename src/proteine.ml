(*
#load "misc_library.cmo"
#load "molecule.cmo"
*)

open Molecule
open Misc_library

(* on va d'abord essayer de définir les types des arcs correctement,
pour pouvoir travailler sur les transitions plus tranquillement *)

type place_type = 
  | Initial_place
  | Regular_place
  | Handle_place of string
  | Catch_place of string
  | Receive_place of string
  | Release_place
  | Send_place of string
  | Displace_mol_place of bool
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



(* classe qui gère les places 
   Une place a un type, et peut contenir un jeton

   Initialisé seulement avec un type de place, 
   ne contient pas de jeton au début
*)
type place_id = int;;
class place (placeType : place_type) =
       
object(self) 
  val mutable tokenHolder = 
    match placeType with
    | Initial_place -> OccupiedHolder emptyToken
    | _ -> EmptyHolder
       
       
  val placeType = placeType
    
  method isEmpty  : bool= tokenHolder = EmptyHolder
  
    (* enlève le token de la place *)
  method empty : unit = tokenHolder <- EmptyHolder
  
    (* met "brutalement" le token donné *)
  method setToken (t : token) : unit  =
    tokenHolder <- OccupiedHolder t
       
(* envoie un token dans la place, depuis une transition; 
   effectue donc les actions données par le type de place *)
  method sendToken (t : token) : unit = 
    match placeType with
    
(* on doit relacher la molecule attachée au token
   pour l'instant, on ne fait que l'enlever, mais en vrai
   il faudrait l'ajouter à l'ensemble des molécules "libres" *)
    | Release_place -> 
       begin 
	 match tokenHolder with
	 | EmptyHolder -> ()
	 | OccupiedHolder t -> 
	    self#setToken emptyToken 
       end
    | Send_place s -> 
       ()


    | Displace_mol_place b -> 
       begin
       match tokenHolder with
       | EmptyHolder -> ()
       | OccupiedHolder t -> 
	  if b 
	  then t#move_forward
	  else t#move_backward
       end
    | _ -> () 
    

  method popToken : token = 
    match tokenHolder with
    | EmptyHolder -> failwith "pop without token"
    | OccupiedHolder t -> 
       self#empty;
      t
	
end;;




(* classe qui gère les transitions 
*)
type transition_id = int;;
class transition (places : place array)  (depL : (place_id * input_link) list) (arrL : (place_id * output_link) list) =

(* fonction qui prends une liste d'arcs entrants 
   et une liste de tokens, et calcule le couple E, mols
   où E est l'énergie totale des tokens, et mols  est 
   la liste des molécules des tokens (qui ont potentiellement
   été coupées
*)
  let rec inputTransitionFunction 
      (ill : input_link list)
      (tokens : token list)
      
      : (moleculeHolder list)
      
      =
    
    match tokens with
      
    | [] -> []
       
    | m :: tokens' -> 
       if m#is_empty
	 
       then 
	 inputTransitionFunction (List.tl ill) tokens'
	   
       else 
	 match ill with
	   
	 | []  -> []
	    
	 | Regular_ilink ::ill' -> 
	    m ::  inputTransitionFunction ill' tokens'
	      
	 | Split_ilink :: ill' -> 
	    let mol1, mol2 = m#cut in
	    mol1 :: mol2 :: inputTransitionFunction ill' tokens'
 
	      

(* fonction qui prends une liste d'arcs entrants 
   une energie et une liste de molécukes, 
   et renvoie une liste de tokens
   Chaque token reçoit la moitié de l'énergie restante

   Attention : il faut bien garder la position précédente du token
*)
  and  outputTransitionFunction 
      (oll : output_link list)
      (mols : moleculeHolder list)
      
      : token list 
      =
    
    match oll with
    | Regular_olink :: oll' -> 
       
     (* oui c'est plutot très moche comme manière de créer un token vide *)
       emptyToken :: outputTransitionFunction oll'  mols
	 
    | Bind_olink :: oll' -> 
       begin
	 match mols with
	 | m1 ::  m2 :: mols' -> 
	    (m1#insert m2) :: outputTransitionFunction oll' mols
	      
	 | m :: [] -> 
	    m  :: outputTransitionFunction oll'  mols
	      
	 | [] -> 
	    (emptyHolder) :: outputTransitionFunction oll' mols
       end
	 
    | Mol_output_olink :: oll' -> 
       begin
	 match mols with 
	 | m :: mols' -> 
	    m  :: outputTransitionFunction oll'  mols
	      
	 | [] -> 
	    emptyToken :: outputTransitionFunction oll'  mols
       end
    | [] -> []
       
  in
  let transitionFunction ill oll tokens = 
    outputTransitionFunction oll (inputTransitionFunction ill tokens)
      
  (* renvoie true ssi les places données en argument n'ont pas de jeton *)
  and placesAreFree (places : place array) (to_try : place_id list): bool =
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
  
  val departurePlaces = dp
  val departureLinks = dl
  val arrivalPlaces = ap
  val arrivalLinks = al

  method getDeparturePlaces = departurePlaces
  method getDepartureLinks = departureLinks
  method getArrivalPlaces = arrivalPlaces
  method getArrivalLinks = arrivalLinks

  method getArrivalTokens (tokens : token list) : token list = 
    transitionFunction departureLinks arrivalLinks tokens
  
  (* potentiel des places de départ relativement au type de la transition *)
  method launchable : bool =
    let rec aux l = 
      match l with
      | h :: t -> 
	 not places.(h)#isEmpty && aux t
      | [] -> true
    in 
    (aux departurePlaces) && placesAreFree places arrivalPlaces
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
    
  method initLaunchables  = 
    let t_l = ref [] in 
    begin
      for i = 0 to Array.length transitions -1 do
	if transitions.(i)#launchable
	then t_l := i :: !t_l
	else ()
      done;
      launchables <- !t_l;
    end
      

  (* on peut faire beaucoup plus efficace, mais pour l'instant 
     on fait au plus simple *)
  method updateLaunchables = self#initLaunchables
    

  (* Lance une transition    *)
  method launchTransition (tId : transition_id) : unit = 
    let initialTokens = List.map 
      (fun x -> places.(x)#popToken) 
      transitions.(tId)#getDeparturePlaces
    in 
    let finalTokens = transitions.(tId)#getArrivalTokens initialTokens
    in 
    List.map 
      (fun (x,y) -> places.(x)#setToken y)
      (zip (transitions.(tId)#getArrivalPlaces) finalTokens);
    ()

  method launchRandomTransition = 
    let t = randomPickFromList launchables in
    self#launchTransition t

end;;
