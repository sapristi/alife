(*
#load "../build/misc_library.cmo";;
#load "../build/molecule.cmo";;
#directory "../build";;

#use "topfind";;
#require "batteries";;
*)

open Batteries
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


type place_id = int;;
type transition_id = int;;

type token = moleculeHolder;;
let emptyToken = emptyHolder;;

(*  un holder est soit vide, soit il contient un unique token *)
type token_holder =
  | EmptyHolder
  | OccupiedHolder of token;;






(* *************************************************************************
				place



   classe qui gère les places 
   Une place a un type, et peut contenir un jeton

   Initialisé seulement avec un type de place, 
   ne contient pas de jeton au début
*)
class place (placeType : place_type) =
       
object(self) 
  val mutable tokenHolder = 
    match placeType with
    | Initial_place -> OccupiedHolder emptyToken
    | _ -> EmptyHolder
       
  val placeType = placeType
    
  method getPlaceType = placeType

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
	
  method addTokenFromMessage  = 
    ()

	
end




(*********************************************************************************
				transitions


classe qui gère les transitions 
*)
and transition (places : place array) (depL : (place_id * input_link) list) (arrL : (place_id * output_link) list) =

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

(* Fonction qui supprime les parties inutiles de la protéine.
   C'est un peu subtil, parceque même un noeud sans transition, 
   ou une transition incomplète peuvent avoir des effets qu'on 
   pourrait vouloir conserver.


   On ne va ici enlever que les trucs qui ne changent rien
   à la fonction de la protéine.


  and accessiblePlaces places depL arrL = 
    let acc = Array.make (Array.length places 
*)  
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
end


(*****************************************************************************************
					protéine

 réseau de Petri entier *)
and proteine (mol : molecule) = 
  (* liste des signatures des transitions *)
  let transitions_signatures_list = buildTransitions mol
    
  (* liste des signatures des places *)
  and places_signatures_list = buildNodesList mol
    
  in


(* on crée de nouvelles places à partir de 
   la liste de types données dans la molécule
*)
  let places_list : place list = 
    List.map 
      (fun x -> new place x)
      places_signatures_list
      
  in 
  
  let (places_array : place array) = Array.of_list places_list

  in
  let (transitions_list : transition list) = 
    List.map 
      (fun x -> let s, ila, ola = x in
		new transition places_array ila ola)
      transitions_signatures_list

  in 
  
  let (transitions_array : transition array) = 
    Array.of_list transitions_list

  (* dictionnaire pour retrouver rapidement les places
     qui reçoivent des messages *)
  
  in
    

  (* fonction qui permet de créer des dictionnaires pour les 
     places qui reçoivent des messages, les places qui attrapent
     des molécules et les poignées
  *)
  let rec createBooks places n = 
    match places with
    | p :: places' ->
       let imb, mcb, hb = createBooks places' (n+1) in 
       begin
	 match p with
	 | Receive_place s -> BatMultiPMap.add s n imb, mcb, hb
	 | Catch_place s -> imb, BatMultiPMap.add s n mcb, hb
	 | Handle_place s -> imb, mcb, BatMultiPMap.add s n hb
	 | _ -> imb, mcb, hb
       end
    | [] -> 
       BatMultiPMap.create String.compare (-), 
      BatMultiPMap.create String.compare (-), 
      BatMultiPMap.create String.compare (-)
      
  in 

  let (inputMessageBook, molCatcherBook, handleBook) = 
    createBooks places_signatures_list 0
    
  in 
  
object(self) 
  val mol = mol
  val transitions = transitions_array
  val places = places_array
  val mutable launchables = []
  val input_message_book = inputMessageBook

  method get_places = places

    
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
      
      
  (* mettre à jour les transitions qui peuvent être lancées.
     Il faut prendre en compte la transition qui vient d'être lancée, 
     ainsi que les tokens qui ont pu arriver par message 

     (du coup, faire plus efficace devient un peu du bazar)
     on peut faire beaucoup plus efficace, mais pour l'instant 
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

  (* lance une transition choisie au hasard parmi celles possibles *)
  method launchRandomTransition = 
    let t = randomPickFromList launchables in
    self#launchTransition t


  (* relaie le message aux places concernées, créant ainsi
     des tokens quand c'est possible *)
  method sendMessage (m : string) = 
    BatSet.PSet.map 
      (fun x -> places.(x)#addTokenFromMessage) 
      (BatMultiPMap.find m inputMessageBook)

(*
  method getMolCatchers = 
    let res = ref [] in 
    for i = 0 to Array.length places - 1 do
      match places.[i] with
      | Node nType -> 
	 begin
	   match nType with
	   | Catch_place pattern -> 
	       b 
*)
end;;






(* plein de problèmes de récursion mutuelle et 
   d'opérations répétées inutilement. On va essayer
   de faire un constructeur externe qui met tout bien
   en place *)



  
