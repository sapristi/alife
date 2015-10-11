type temp_blank = int;

type transition = int list * int list;

class petri_net initial_tokens transitions =
object
  
  val mutable tokens = Array.copy initial_tokens
  val transitions = transitions

  val places_number = Array.length initial_tokens
    
  method check_init =
    let rec check_transition t =
      (* si on faisait du coq, ce serait encore plus beau *)
      match t with
      | h :: t, l2 ->
	 h >= 0 && h < places_number && check_transition (t,l2)
      | [], h :: t -> 
	 h >= 0 && h < places_number && check_transition ([],t)
      | _ -> true
	 
    and check_transitions t_list =
      match t_list with
      | [] -> true
      | t :: t_list' ->
	 check_transition t && check_transitions t_list'
    in
    check_transitions transitions

      
  method fire_transitions =

    
    let rec tokens_in_places l =
      match l with
      | n :: l' -> tokens.(n) >= 1 && tokens_in_places l'
      | [] -> true
	 
    and fireables t_list =
      match t_list  with
      | t :: t_list' ->
	 let (l,_) = t in
	 if tokens_in_places l 
	 then t :: fireables t_list
	 else t_list
	   
    and fire_transition t =
      match t with
      | h :: t, _ ->
	 tokens.(h) <- tokens.(h) - 1
      | [], h :: t ->
	 tokens.(h) <- tokens.(h) + 1
      | _ -> ()
	 
    and fire_transitions t_list = List.map fire_transition t_list

    in
    fire_transitions (fireables transitions)
      
end;;


module type PETRI_TYPES =
sig
  type node
  type place
  type token
  val fireable : place ->  bool
  val fire : place -> token
  val add_token : place -> token -> place
  val node_id : node -> int
  val place_id : place -> int
end;;




module Petri_net =
  functor (PTypes  : PETRI_TYPES) ->
struct
  type node = PTypes.node
  type place = PTypes.place
  type token = PTypes.token

  type transition = ( node list * place * node list)
    

  class petri_net (places_i ) (nodes_i ) (transitions_i ) =
  object

    val places = places_i
    val nodes = nodes_i
    val transitions = transitions_i

    val places_number = Array.length places_i
    val nodes_number = Array.length nodes_i
      
    method check_init =
      
      let rec check_places =
	let res = ref false in
	for i = 0 to places_number do
	  res := !res && PTypes.place_id places.(i) = i
	done;
	!res

      and check_nodes = 
	let res = ref false in
	for i = 0 to places_number do
	  res := !res && PTypes.node_id nodes.(i) = i
	done;
	!res

      and check_transition t =
      (* si on faisait du coq, ce serait encore plus beau *)
	match t with
	| h :: t, l2 ->
	   PTypes.node_id h >= 0 && PTypes.node_id h < places_number && check_transition (t,l2)
	| [], h :: t -> 
	   PTypes.node_id h >= 0 && PTypes.node_id h < places_number && check_transition ([],t)
	| _ -> true
	   
      and check_transitions t_list =
	match t_list with
	| [] -> true
	| t :: t_list' ->
	   check_transition t && check_transitions t_list'
      in
      check_transitions transitions && check_places && check_nodes

    (* en fait c'est pas si facile émile 


    method fire_transitions =

      let rec tokens_in_places places_l =
	match places_l with
	| place :: places_l' -> PTypes.fireable place && tokens_in_places places_l'
	| [] -> true
	   
      and fireables transitions_l =
	match transitions_l  with
	| transition :: transitions_l' ->
	   let (left_places,_) = transition in
	   if tokens_in_places left_places 
	   then transitions :: fireables transitions_l'
	   else transitions_l'
	     
      and fire_transition t =
	match t with
	| h :: t, _ ->
	   tokens.(h) <- tokens.(h) - 1
	| [], h :: t ->
	   tokens.(h) <- tokens.(h) + 1
	| _ -> ()
	   
      and fire_transitions t_list = List.map fire_transition t_list
	
      in
      fire_transitions (fireables transitions)
    *)
	
  end
end;;
