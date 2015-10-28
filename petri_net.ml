
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



class virtual transition (tt : transition_type) (td : place array) (ta : place array) =
  let getTransitionSignature tt =
    match tt with
    | SplitT -> [| MolHolder_type |]
    | BindT -> [| MolHolder_type , MolHolder_type |]
    | SendT -> [| AnyT |]
    | ReceiveT -> [| AnyT |]
  in
  
object
  val departures = td
  val arrivals = ta

  method virtual getArrivalTokens :  transition_type ->  token array -> token array

  method getPotential (places : place array) =

    let ( _ ,(startPlaces, stopPlaces)) = pnTransitions.(tId) in
    
    let firePotential =
      Array.fold_left
	(fun e sp ->
	  if e = -1
	  then -1
	  else
	    let e' = startPlaces.(sp
	      self#energyOfTokenInPlaceOfType  pId tt in
	    if e' = -1
	    then -1
	    else e + e')
	0 startPlaces

    and placesAreFree places =
      Array.fold_left
	(fun res sp ->
	  let pId,_ = sp in
	  match places.(pId) with
	  | EmptyPlace -> res
	  | _ -> false)
	true places
	 
    in
    if placesAreFree stopPlaces
    then getFirePotential startPlaces
    else -1
end;;



class petri_net
  (placesNumber : int) (transitions : transition array) (initialTokens : (place_id * token) list) =
  

       
  and initPlaces (placesNumber : int) (initialTokens : (place_id * token) list) : place array =
    let res = Array.make placesNumber EmptyPlace in
    let rec aux tokens =  
      match tokens with
      | (pId, t) :: tokens'->
	 res.(pId) <- OccupiedPlace t;
	aux tokens'
      | [] -> ()
    in
    aux initialTokens;
    res

  in
  
object(self)
  
  val pnTransitions = Array.copy transitions
  val pnPlaces = initPlaces placesNumber initialTokens
    
    
  (* renvoie l'energie du token de la place placeId si il
     est du type tTypeToTest, et -1 sinon *)
  method private energyOfTokenInPlaceOfType
    (placeId : place_id) (tTypeToTest : token_type) : energy =
    match places.(placeId) with
    | EmptyPlace -> -1
    | OccupiedPlace (e, tt) -> 
       if sameTokenType tTypeToTest tt
       then e
       else -1
      
      
  (* renvoie le potentiel de la transition :
     somme des énergies des token si on peut la lancer,  -1 sinon  *)
  method private getTransitionPotential  (tId : transition_id) : energy =
    let ( _ ,(startPlaces, stopPlaces)) = pnTransitions.(tId) in
    
    let rec getFirePotential startPlaces  =
      Array.fold_left
	(fun e sp ->
	  if e = -1
	  then -1
	  else
	    let pId, tt = sp in 
	    let e' = self#energyOfTokenInPlaceOfType  pId tt in
	    if e' = -1
	    then -1
	    else e + e')
	0 startPlaces

    and placesAreFree places =
      Array.fold_left
	(fun res sp ->
	  let pId,_ = sp in
	  match places.(pId) with
	  | EmptyPlace -> res
	  | _ -> false)
	true places
	 
    in
    if placesAreFree stopPlaces
    then getFirePotential startPlaces
    else -1

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
  


