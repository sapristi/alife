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



open Types
open MyMolecule


(* il faudrait faire attention aux molécules vides (ie liste vide),
   et peut-être transformer les tokens qui contiennent une molécule vide
   en token vide (mais pas sûr) *)
module Token =
struct 
  type t = Empty | MolHolder of MoleculeHolder.t
  let is_empty token = token = Empty
  let empty = Empty
  let make mol = MolHolder (MoleculeHolder.make mol)
  let set_mol mol token = MolHolder (MoleculeHolder.make mol)
end;;



type container = < send_message : string -> unit; add_molecule : molecule -> unit >;;



(* *************************************************************************
				place
   classe qui gère les places. Une place a un type, et peut contenir un jeton
   Initialisé seulement avec un type de place, ne contient pas de jeton au début
*)


module Place =
struct 
  type token_holder = EmptyHolder | OccupiedHolder of Token.t
      
  type t =
    {tokenHolder : token_holder;
     placeType : place_type;
     host : container;}

  let make (pt : place_type) (h : container) : t =
    {tokenHolder = EmptyHolder;
     placeType = pt;
     host = h;}
      
  let is_empty (p : t) : bool =
    p.tokenHolder = EmptyHolder
    
  let remove_token (p : t) : t=
    {tokenHolder = EmptyHolder;
     placeType = p.placeType;
     host = p.host;}
      
  let set_token (token : Token.t) (p : t) : t =
    {tokenHolder = OccupiedHolder token;
     placeType = p.placeType;
     host = p.host;}

  (* Token ajouté par le lancement d'une transition.
  Il faut appliquer les effets de bord suivant le type de place *)
  let add_token_from_transition (inputToken : Token.t) (p : t) : t=
    if is_empty p
    then 
      match p.placeType with
	
      (* il faut dire à l'host de relacher la molecule attachée au token
      est ce qu'on vire aussi le token ??? *)
      | Release_place -> 
	 begin
	   p.host#add_molecule MoleculeHolder.get_molecule inputToken;
	   set_token Token.empty p
	 end
	   
      (* il faut faire broadcaster le message par l'host *)
      | Send_place s ->
	 begin
	   p.host#send_message s;
	   set_token inputToken p
	 end
      (* il faut déplacer la molécule du token *)
      | Displace_mol_place b ->
	 begin
	   match inputToken with
	   | Empty -> set_token inputToken
	   | MolHolder m ->
	      if b
	      then set_token
		(Token.set_mol (MoleculeHolder.move_forward m) inputToken)
	      else set_token
		(Token.set_mol (MoleculeHolder.move_backward m) inputToken)
	 end
      | _ ->  set_token inputToken p
    else
      failwith "non empty place received a token from a transition"


(* Token ajouté par un broadcast de message.
   Il faudrait peut-être bien vérifier que la place reçoit des messages,
   que le message correspond, tout ça tout ça *)
  let add_token_from_message (p : t) : t =
    if is_empty p
    then set_token Token.empty p
    else p
      
  let add_token_from_binding (mol : molecule) (p : t) : t =
    if is_empty p
    then
      set_token (Token.make mol)
    else
      failwith "cannot bind because a token is already present"
	
  let pop_token (p : t) : Token.t * t =
    match p.tokenHolder with
    | EmptyHolder -> failwith "cannot pop token from empty place"
    | OccupiedHolder token -> token, remove_token p
	
end;;


(*********************************************************************************
				transitions


classe qui gère les transitions 
*)

module Transition =
struct
  
  type t  =
    {places : Place.t array;
     departure_places : int array;
     arrival_places : int array;
     departure_links : input_link array;
     arrival_links : output_link array;
    }


  let places_are_occupied (places :  place array) (to_try : int list): bool =
    List.fold_left
      (fun res pId -> (not Place.is_empty places.(pId)) && res )
      true to_try
  and places_are_free  (places :  place array) (to_try : int list): bool =
    List.fold_left
      (fun res pId -> Place.is_empty places.(pId) && res )
      true to_try  
  in
  let launchable (transition : t) =
    places_are_free transition.arrival_places && place_are_occupied transition.departure_places
      
      
(* fonction qui prends une liste d'arcs entrants et une liste de tokens, 
   et calcule  la liste des molécules des tokens (qui ont potentiellement
   été coupées *)
  let rec input_transition_function 
      (ill : input_link list)
      (tokens : Token.t list)
      : (MoleculeHolder.t list)   =
    
    match tokens with
    | [] -> []
    | token :: tokens' ->
       match token with
       | Empty -> input_transition_function (List.tl ill) tokens'
       | MolHolder mol -> 
	  match ill with
	  | []  -> []
	  | Regular_ilink ::ill' -> 
	     mol ::  input_transition_function ill' tokens'
	  | Split_ilink :: ill' -> 
	     let mol1, mol2 = MoleculeHolder.cut mol in
	     mol1 :: mol2 :: input_transition_function ill' tokens'
	       
(* fonction qui prends une liste d'arcs entrants et une liste de molécukes, 
   et renvoie une liste de tokens  *)
  and  output_transition_function 
      (oll : output_link list)
      (mols : MoleculeHolder.t list)
      : Token.t list =
    
    match oll with
    | Regular_olink :: oll' -> 
       Token.empty :: output_transition_function oll'  mols
    | Bind_olink :: oll' -> 
       begin
	 match mols with
	 | m1 ::  m2 :: mols' -> 
	    Token.make (MoleculeHolder.insert m1 m2) :: output_transition_function oll' mols
	 | m :: [] -> 
	    Token.make m  :: output_transition_function oll'  mols	      
	 | [] -> 
	    Token.empty :: output_transition_function oll' mols
       end
	 
    | Mol_output_olink :: oll' -> 
       begin
	 match mols with 
	 | m :: mols' -> 
	    Token.make m  :: output_transition_function oll'  mols
	 | [] -> 
	    Token.empty :: output_transition_function oll'  mols
       end
    | [] -> []
       
  in
  let make_transition_function ill oll tokens = 
    output_transition_function oll (input_transition_function ill tokens)
  in
  let transition_function (inputTokens : Token.t list) (transition : t) = 
    make_transition_function transition.departure_links transition.arrival_links tokens
end;;


(*****************************************************************************************
					protéine

											  réseau de Petri entier *)

module Proteine =
struct

  
  type t =
    {mol : molecule;
     transitions : Transition.t array;
     places : Place.t array;
     launchables : int list;
     messageReceptorsBook : (string * int) BatMultiPMap;
     handlesBook : (string * int) BatMultiPMap;
     molCatchersBook : (string * int) BatMultiPMap;}

  let modify_launchables new_launchables prot = 
    let {mol =  m; transitions = ts; places = ps;
	 launchables = _; messageReceptorsBook = mb;
	 handlesBook = hb;  molCacthersBook = cb} = prot
    in {mol =  m; transitions = ts; places = ps;
	launchables = new_launchables; messageReceptorsBook = mb;
	handlesBook = hb; molCacthersBook = cb}

  let modify_places ids new_places prot =
    let new_places = Array.copy prot.places in
    

    
  let make (mol : Molecule.t) : t = 
  (* liste des signatures des transitions *)
    let transitions_signatures_list = build_transitions mol
  (* liste des signatures des places *)
    and places_signatures_list = build_nodes_list mol
  in
(* on crée de nouvelles places à partir de 
   la liste de types données dans la molécule*)
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
     des molécules et les poignées *)
    let rec create_books 
	(places : place_type list) 
	(n : int)
	: (((string, int) BatMultiPMap.t)
	   * ((string, int) BatMultiPMap.t) 
	   * ((string, int) BatMultiPMap.t))
	=
      match places with
      | p :: places' ->
	 let imb, mcb, hb = create_books places' (n+1) in 
	 begin
	   match p with
	   | Receive_place s -> BatMultiPMap.add s n imb, mcb, hb
	   | Catch_place s -> imb, BatMultiPMap.add s n mcb, hb
	   | Handle_place s -> imb, mcb, BatMultiPMap.add s n hb
	   | _ -> imb, mcb, hb
	 end
      | [] -> 
	 (
	   BatMultiPMap.create String.compare (-), 
	   BatMultiPMap.create String.compare (-), 
	   BatMultiPMap.create String.compare (-)
	 )
    in 
    let (input_message_book, mol_catcher_book, handle_book) = 
      create_books places_signatures_list 0
    in 
    {mol = mol;
     transitions = transitions_array;
     places = places_array;
     launchables = [];
     messageReceptorsBook = input_message_book;
     handlesBook = handle_book;
     molCatchersBook = mol_catcher_book;}
      
  let init_launchables p = 
    let t_l = ref [] in 
    begin
      for i = 0 to Array.length transitions -1 do
	if transitions.(i)#launchable
	then t_l := i :: !t_l
	else ()
      done;
      modify_launchables !t_l p
    end

      
  (* mettre à jour les transitions qui peuvent être lancées.
     Il faut prendre en compte la transition qui vient d'être lancée, 
     ainsi que les tokens qui ont pu arriver par message 

     (du coup, faire plus efficace devient un peu du bazar)
     on peut faire beaucoup plus efficace, mais pour l'instant 
     on fait au plus simple *)
  let update_launchables p =
    init_launchables p


  let launch_transition (tId : int) p = 
    let initialTokens, emptied_departure_places =
      List.fold_left 
	(fun ll x ->
	  let t, p = Place.pop_token p.places.(x) in
	  let tl, pl = ll in
	  t :: tl, p :: pl)
	([], [])
	p.transitions.(tId).departure_places
    in 
    let finalTokens = Transition.transition_function initialTokens p.transitions.(tId)
    in
    let updated_arrival_places = 
      List.map 
	(fun (x,y) -> Place.set_token y places.(x))
	(zip (p.transitions.(tId).arrival_places) finalTokens)
    in {
    ()
      
      
and  proteine (mol : molecule) = 
  
object(self) 
  val mol : molecule = mol
  val transitions = transitions_array
  val places : place array = places_array
  val mutable launchables = []
  val maps = input_message_book, mol_catcher_book, handle_book

      
    
    
  (* Lance une transition    *)
  method launch_transition (tId : transition_id) : unit = 

  (* lance une transition choisie au hasard parmi celles possibles *)
  method launch_random_transition = 
    let t = random_pick_from_list launchables in
    self#launch_transition t


  (* relaie le message aux places concernées, créant ainsi
     des tokens quand c'est possible *)
  method send_message (m : string) = 
    BatSet.PSet.map 
      (fun x -> places.(x)#add_token_from_message) 
      (BatMultiPMap.find m input_message_book)

  method set_host (h : container) : unit = 
    Array.map (fun x -> x#setHost h) places;
    ()

  method bind_mol (m : molecule) (pat : string) : bool = 
    let _,catchers,_ = maps in 
    let targets = BatMultiPMap.find pat catchers in
    let bindSiteId = Misc_library.random_pick_from_PSet targets in
    places.(bindSiteId)#add_token_from_binding m


end;;






  
