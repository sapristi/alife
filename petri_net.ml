
type energy = int;;



(*  type de token : représente l'objet associé à un token *)
type token_type =
  | Neutral
  | MolHolder of string
  | Messsage of int
;;

(* sert pour définir les transitions, dont les places
   de départ doivent contenir des tokens d'un type donné *)
type token_type_id =
  | Neutral_type
  | Message_type
  | MolHolder_type
;;

type token = energy * token_type;;



(*  un holder est soit vide, soit il contient un unique token *)
type token_holder =
  | EmptyHolder
  | OccupiedHolder of token;;



type place_type =
  | Label
  | Handle
  | Regular;;




(* le nombre de tokens au départ et à l'arrivée, et le type de ces tokens,
   dépendent du type de transition 
   ---> il faudrait coder quelque chose pour ça *)
type transition_type =
  | AnyT
  | SplitT
  | BindT
  | SendT
  | ReceiveT;;







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
      | Message _ -> if tti = Message_type then true else false
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
  (* renvoie la signature d'un type de transition *)
  let getTransitionSignature tt =
    match tt with
    | SplitT -> [| MolHolder_type |]
    | BindT -> [| MolHolder_type , MolHolder_type |]
    | SendT -> [| AnyT |]
    | ReceiveT -> [| AnyT |]

  (* renvoie true ssi les places données en argument n'ont pas de jeton *)
  and placesAreFree places =
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


(* classe qui gère le réseau de pétri entier
   
   Initialisé avec un tableau de places, un tableau de transitions,
   et les tokens initiaux


   À faire : 
   --- copier les tableaux pour l'initialisation ?
*)
class petri_net
  (placesNumber : int) (places : place array) (transitions : transition array) (initialTokens : (place_id * token) list) =

       
  and rec initTokens (places : place array) (initialTokens : (place_id * token) list) : nil  =
  match tokens with
  | (pId, t) :: tokens'->
     places.(pId)#setToken t;
    initTokens tokens'
  | [] -> ()
  in
  
object(self)
  
  val pnTransitions = transitions
  val pnPlaces = places
    
  initializer initTokens places initialTokens
    
      
      

      (*           INCOMPLET

	 lance une transition;
	 à compléter pour implémenter la fonction effectuée par la transition
	 sur l'objet associé au jeton *)
  method fireTransition (tId : transition_id) : nil =
    let tt,(startPlaces, stopPlaces) = pnTransitions.(tId) in
    
    let extractStartTokens placesId =
      Array.map
	(fun td -> let pId, tt = td in
		   match pnPlaces.(pId) with
		   | EmptyPlace -> failwith "tout est cassé"
		   | OccupiedPlace t ->
		      pnPlaces.(pId) <- EmptyPlace;  t) placesId
	
    and getFinalTokens initialTokens tt = 
      
	
end;;
  


