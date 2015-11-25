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
    type nodeType = place
    type inputLinkType = input_link
    type outputLinkType = output_link
end;;


module MyMolecule = MolManagement(MolTypes);;
open MyMolecule

type energy = int;;

type token_type =
  | Empty_token
  | Mol_binder_token of moleculeHolder
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

    : energy * (moleculeHolder list)
        
 =
  
  match tokens with

  | [] -> (0,[])
     
  | (e, Empty_token) :: tokens' -> 
     let total_e, mol_list = input_transition (List.tl ila) tokens' in
     (e + total_e), mol_list

  | (e, (Mol_binder_token m)) :: tokens' -> 

     match ila with
     
     | []  -> (0,[])
     
     | Regular_ilink ::ila' -> 
	let total_e, mol_list = input_transition ila' tokens' in
	(e + total_e), m :: mol_list
     
     | Split_ilink :: ila' -> 
	let mol1, mol2 = m#cut in
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
    (mols : moleculeHolder list)
    
    : token list 
 =
  
  match ola with
  | Regular_olink :: ola' -> 
     ((e / 2), Empty_token) :: output_transition ola' (e - e/2) mols
 
  | Bind_olink :: ola' -> 
     begin
       match mols with
       | m1 ::  m2 :: mols' -> 
	  ((e / 2), Mol_binder_token (m1#insert m2)) :: output_transition ola' (e - e/2) mols
	    
       | m :: [] -> 
	  ((e / 2), Mol_binder_token m ) :: output_transition ola' (e - e/2) mols
	    
       | [] -> 
	  ((e / 2), Empty_token) :: output_transition ola' (e - e/2) mols
     end

  | Mol_output_olink :: ola' -> 
     begin
       match mols with 
       | m :: mols' -> 
	  ((e / 2), Mol_binder_token m ) :: output_transition ola' (e - e/2) mols

       | [] -> 
	  ((e / 2), Empty_token) :: output_transition ola' (e - e/2) mols
     end
  | [] -> []
;;       

(* classe qui gère les places 
   Une place a un type, et peut contenir un jeton

   Initialisé seulement avec un type de place, 
   ne contient pas de jeton au début
*)
class place (placeType : place_type) =
       
object 
  val mutable tokenHolder = EmptyHolder
  val placeType = placeType

  method isEmpty  : bool= tokenHolder = EmptyHolder
  method empty : unit = tokenHolder <- EmptyHolder
  method setToken (t : token) : unit  =
    tokenHolder <- OccupiedHolder t
       
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
class virtual transition  (td : place_id array) (ta : place_id array) =


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
