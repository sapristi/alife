#load "molecule.cmo"
open Molecule


(* on va d'abord essayer de définir les types des arcs correctement,
pour pouvoir travailler sur les transitions plus tranquillement *)

type place = 
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
    type nodeType = place
    type inputLinkType = input_link
    type outputLinkType = output_link
end;;


module MyMolecule = MolManagement(MolTypes);;
open MyMolecule

type energy = int;;
type token_type =
  | Empty_token
  | Mol_binder_token of molecule * int
;;
type token = energy * token_type;;

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
let rec input_transition 
    (ila : input_link list)
    (tokens : token list)

    : energy * (molecule list)
        
 =
  
  match tokens with

  | [] -> (0,[])
     
  | (e, Empty_token) :: tokens' -> 
     let total_e, mol_list = input_transition (List.tl ila) tokens' in
     (e + total_e), mol_list

  | (e, (Mol_binder_token (m, p))) :: tokens' -> 

     match ila with
     
     | []  -> (0,[])
     
     | Regular_ilink ::ila' -> 
	let total_e, mol_list = input_transition ila' tokens' in
	(e + total_e), m :: mol_list
     
     | Split_ilink :: ila' -> 
	let mol1, mol2 = MyMolecule.cut m p in
	let total_e, mol_list = input_transition ila' tokens' in
	(e + total_e), mol1 :: mol2 :: mol_list
;;       


(* fonction qui prends une liste d'arcs entrants 
   une energie et une liste de molécukes, 
   et renvoie une liste de tokens
   Chaque token reçoit la moitié de l'énergie restante

   Attention : il faut bien garder la position précédente du token
*)
let rec output_transition 
    (ola : output_link list)
    (e : energy)
    (mols : molecule list)
    
    : token list 
 =
  
  match ola with
  | Regular_olink :: ola' -> 
     ((energy / 2), Empty_token) :: output_transition ola' (e - e/2) mols
 
  | Bind_olink :: ola' -> 

  | Mol_output_olink :: ola' -> 
     match mols with 
     | m :: mols' -> 
	((energy / 2), Mol_binder_token m,0 ) :: output_transition ola' (e - e/2) mols

  | [] -> []
;;       

(* classe qui gère les places 
   Une place a un type, et peut contenir un jeton

   Initialisé seulement avec un type de place, 
   ne contient pas de jeton au début
*)
class place (placeType : place_type) =
  
  (* teste si un token est de type donné *) 
  let tokenOfType (tt : token_type) (tti : token_type_id) : bool =
    if tti = AnyT
    then true
    else 
      match tt with
      | Neutral  -> if tti = Neutral_type then true else false
      | MolHolder  _  -> if tti = MolHolder_type then true else false
  in
       
object 
  val mutable tokenHolder = EmptyHolder
  val placeType = placeType

  method isEmpty = tokenHolder = EmptyHolder
  method empty = tokenHolder <- EmptyHolder
  method setToken t =
    tokenHolder <- OccupiedHolder t

  method getEnergyOfType (tti : token_type_id) : energy =
    match tokenHolder with
    | EmptyHolder -> -1
    | OccupiedHolder (e,tt) ->
       if tokenOfType tt tti
       then e
       else -1
       
end;;




(* classe qui gère les transitions 
   Une transition a un type, duquel dépend sa signature, 
   et relie des places de départ avec des places d'arrivée

   Initialisé avec un type de transition, et deux tableaux
   de numéros de places : un pour le départ, un pour l'arrivée

   À faire : 
   --- La signature contient le nombre de places d'arrivée
   --- Méthode pour lancer la transition (avec gestion des 
   jetons et données associées, selon le type de transition)
*)
class virtual transition (tt : transition_type) (td : place_id array) (ta : place_id array) =


  (* renvoie true ssi les places données en argument n'ont pas de jeton *)
  let placesAreFree places =
    Array.fold_left
      (fun res pId ->
	if places.(pId)#isEmpty
	then res
	else false
      )
      true places
  in
   
object
  val tt = tt
  val signature = getTransitionSignature tt
  val departures = td
  val arrivals = ta

  method virtual getArrivalTokens :  transition_type ->  token array -> token array

  (* potentiel des places de départ relativement au type de la transition *)
  method private getDeparturePotential (places : place array) =
    let res = ref 0 in
    if Array.length departures = Array.length signature
    then 
      for i = 0 to Array.length departures do
	if !res != -1
	then
	  let e = places.(departures.(i))#getEnergyOfType signature.(i) in
	  if e >= 0 
	  then res := !res + e
      done
    else ();
    !res

  (* renvoie le potentiel de départ si on peut lancer la transition, -1 sinon *)
  method getPotential (places : place array) =
    if placesAreFree arrivals
    then getDeparturePotential places
    else -1	
end;;
