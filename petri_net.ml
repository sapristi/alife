
type energy = int;;


(*  type de token : représente l'objet associé à un token *)
type token_type =
  | Empty
  | Neutral
  | Placeholder of int;;
type token = energy * token_type;;


(*  une place est soit vide, soit elle contient un unique token *)
type place =
  | EmptyPlace
  | OccupiedPlace of token;;
type place_id = int;;

type transition_type =
  | Action
  | Split
  | Bind
  | Send
  | Receive;;

type transition = transition_type * ((place_id * token_type) list * (place_id * token_type) list) ;;
type transition_id = int;;

type petri_net = place array * transition array;;


class petri_net
  (placesNumber : int) (transitions : transition array) (initialTokens : (place_id * token) list) =
  
  (* teste si deux types token sont de même type *) 
  let sameTokenType (t1 : token_type) (t2 : token_type) : bool =
    match t1 with
    | Empty -> begin match t2 with | Empty -> true | _ -> false end
    | Neutral  -> begin match t2 with | Neutral -> true | _ -> false end
    | Placeholder n  -> begin match t2 with | Placeholder n' -> true | _ -> false end
       
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
  
  val transitions = Array.copy transitions
  val places = initPlaces placesNumber initialTokens
    
    
  (* renvoie l'energie du token de la place placeId si il
     est du type tTypeToTest, et -1 sinon *)
  method energyOfTokenInPlaceOfType
    (placeId : place_id) (tTypeToTest : token_type) : energy =
    match places.(placeId) with
    | EmptyPlace -> -1
    | OccupiedPlace (e, tt) -> 
       if sameTokenType tTypeToTest tt
       then e
       else -1
      
      
  (* renvoie le potentiel de la transition :
     somme des énergies des token si on peut la lancer,  -1 sinon  *)
  method getTransitionPotential  (tId : transition_id) : energy =
    let ( _ ,(startPlaces, stopPlaces)) = transitions.(tId) in
    
    let rec getFirePotential startPlaces  =
      match startPlaces with
      | (pId, tt) :: startPlaces' ->
	 let e = self#energyOfTokenInPlaceOfType  pId tt in
	 if e = -1
	 then -1
	 else
	   let e' = getFirePotential startPlaces'  in
 	   if e' = -1
	   then -1
	   else e + e'
      | [] -> 0
	 
    and freeStopPlaces stopPlaces =
      match stopPlaces with
      | (pId, _) :: stopPlaces' ->
	 begin
	   match places.(pId) with
	   | EmptyPlace -> freeStopPlaces stopPlaces'
	   | _ -> false
	 end
      | [] -> true
	 
	 
    in
    if freeStopPlaces stopPlaces
    then getFirePotential startPlaces
    else -1

      (*           INCOMPLET

	 lance une transition;
	 à compléter pour implémenter la fonction effectuée par la transition
	 sur l'objet associé au jeton *)
  method fireTransition (tId : transition_id) : nil =
    let _,(startPlaces, stopPlaces) = transitions.(tId) in
    let rec removeTokens places =
      match placesId with
      | pId :: placesId' -> places.(pId) <- EmptyPlace
    in
    removeTokens startPlaces
	
end;;
  


