
(*
#use "topfind";;
#require "batteries";;
#require "yojson" ;;
#require "ppx_deriving_yojson";;
#require "ppx_deriving.show";;



Used to add directories to load librairies (cmo). Can be avoided using -I "path" when launching toplevel.

#directory "/home/sapristi/Documents/projets/alife/_build/src/libs";;
#directory "/home/sapristi/Documents/projets/alife/_build/src/bacterie";;

    
#load "misc_library.cmo";;
#load "molecule.cmo";;
#load "custom_types.cmo";;
 *)


open Batteries
open Molecule
open Misc_library
open Custom_types
open MyMolecule
open Maps


(* il faudrait faire attention aux molécules vides (ie liste vide),
   et peut-être transformer les tokens qui contiennent une molécule vide
   en token vide (mais pas sûr) *)
module Token =
struct 
  type t = Empty | MolHolder of MoleculeHolder.t
      [@@deriving show]
  let is_empty token = token = Empty
  let empty = Empty
  let make mol = MolHolder mol
  let set_mol mol token = MolHolder mol

  let to_string token =
    match token with
    | Empty -> "token (empty)"
    | MolHolder mh -> "token (molecule)"


  let to_json token =
    match token with
    | Empty -> `String "token (empty)"
    | MolHolder mh -> `String "token (molecule)"
    
end

type return_action =
  | AddMol of MoleculeHolder.t
  | SendMessage of string
  | NoAction
      [@@deriving show]


(* ********************************************************
				place
   Module qui gère les places. Une place a un type, et peut 
   contenir un jeton. Initialisé seulement avec un type de 
   place.
*)


module Place =
struct 
  type token_holder = EmptyHolder | OccupiedHolder of Token.t
      [@@deriving show]

  let token_holder_to_json (th : token_holder) : Yojson.Safe.json =
    match th with
    | EmptyHolder -> `String "no token"
    | OccupiedHolder t -> Token.to_json t
       
  type t =
    {mutable tokenHolder : token_holder;
     placeType : place_type;}
      [@@deriving show]

  let make (placeType : place_type) : t =
    if placeType = Initial_place
    then {tokenHolder = OccupiedHolder Token.empty; placeType;}
    else {tokenHolder = EmptyHolder; placeType;}
      
  let is_empty (p : t) : bool =
    p.tokenHolder = EmptyHolder
    
  let remove_token (p : t) : unit=
    p.tokenHolder <- EmptyHolder
      
  let set_token (token : Token.t) (p : t) : unit =
    p.tokenHolder <- OccupiedHolder token
      
  (* Token ajouté par le lancement d'une transition.
     Il faut appliquer les effets de bord suivant le type de place *)
  let add_token_from_transition (inputToken : Token.t) (p : t) : return_action=
    if is_empty p
    then 
      match p.placeType with
	
      (* il faut dire à l'host qu'on a  relaché la 
	 molecule attachée au token.
	 est ce qu'on vire aussi le token ??? *)
      | Release_place ->
	 (
	   match inputToken with
	   | Token.Empty -> set_token Token.empty p; NoAction
	   | Token.MolHolder m -> set_token Token.empty p; AddMol m
	 );
	   
	   
      (* il faut faire broadcaster le message par l'host *)
      | Send_place s ->
	 begin
	   set_token inputToken p;
	   SendMessage s
	 end
      (* il faut déplacer la molécule du token *)
      | Displace_mol_place b ->
	 begin
	   (
	   match inputToken with
	   | Token.Empty -> set_token inputToken p
	   | Token.MolHolder m ->
	      if b
	      then set_token
		(Token.set_mol (MoleculeHolder.move_forward m) inputToken) p
	      else set_token
		(Token.set_mol (MoleculeHolder.move_backward m) inputToken) p
	   );
	   NoAction
	 end
      | _ ->  set_token inputToken p; NoAction
    else
      failwith "non empty place received a token from a transition"


(* Token ajouté par un broadcast de message.
   Il faudrait peut-être bien vérifier que la place reçoit des messages,
   que le message correspond, tout ça tout ça *)
  let add_token_from_message (p : t) : unit =
    if is_empty p
    then set_token Token.empty p

  (* on renvoie un booléen pour faire remonter facilement si 
     le binding était possible ou pas *)
  let add_token_from_binding (mol : molecule) (p : t) : bool =
    if is_empty p
    then
      ( set_token (Token.make (MoleculeHolder.make mol)) p;
	true )
    else
      false
	
  let pop_token (p : t) : Token.t =
    match p.tokenHolder with
    | EmptyHolder -> failwith "cannot pop token from empty place"
    | OccupiedHolder token ->
       ( remove_token p;
	 token )

  let to_json (p : t) =
    `Assoc [("token", token_holder_to_json p.tokenHolder); ("type", Custom_types.place_type_to_yojson p.placeType)]
end;;


(**********************************************
                 transitions
***********************************************)

module Transition =
struct
  type t  =
    {places : Place.t array;
     departure_places : int list;
     arrival_places : int list;
     departure_links : transition_input_type list;
     arrival_links : transition_output_type list;
    }
      [@@deriving show]

  let launchable (transition : t) =
    let places_are_occupied (places :  Place.t array) (to_try : int list): bool =
      List.fold_left
	(fun res pId -> (not (Place.is_empty places.(pId))) && res )
	true to_try
    and places_are_free  (places :  Place.t array) (to_try : int list): bool =
      List.fold_left
	(fun res pId -> Place.is_empty places.(pId) && res )
	true to_try  
    in
    (places_are_free transition.places transition.arrival_places)
    && (places_are_occupied transition.places transition.departure_places)
      
      
  let make (places : Place.t array)
      (depL : (int * transition_input_type) list)
      (arrL : (int * transition_output_type) list) =
  let departure_places, departure_links = unzip depL and 
      arrival_places, arrival_links = unzip arrL 
  in {places; departure_places; arrival_places;
      departure_links; arrival_links;}

  
  let transition_function (inputTokens : Token.t list) (transition : t) =
    
  (* fonction qui prends une liste d'arcs entrants et une liste de tokens, 
     et calcule  la liste des molécules des tokens (qui ont potentiellement
     été coupées *)
    let rec input_transition_function 
	(ill : transition_input_type list)
	(tokens : Token.t list)
	: (MoleculeHolder.t list)   =
      
      match tokens with
      | [] -> []
      | token :: tokens' ->
	 match token with
	 | Token.Empty -> input_transition_function (List.tl ill) tokens'
	 | Token.MolHolder mol -> 
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
	(oll : transition_output_type list)
	(mols : MoleculeHolder.t list)
	: Token.t list =
      
      match oll with
      | Regular_olink :: oll' -> 
	 Token.empty :: output_transition_function oll'  mols
      | Bind_olink :: oll' -> 
	 begin
	   match mols with
	   | m1 ::  m2 :: mols' -> 
	      (Token.make (MoleculeHolder.insert m1 m2)) :: output_transition_function oll' mols
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
    
    output_transition_function
      transition.arrival_links
      (input_transition_function
	 transition.departure_links
	 inputTokens)


  let to_json (trans : t) : Yojson.Safe.json =
    `Assoc [
      "dep_places",
      `List (List.map2
	       (fun x y -> `List (`Int x :: [Custom_types.transition_input_type_to_yojson y]))
		 trans.departure_places trans.departure_links);
      "arr_places", 
      `List (List.map2 (fun x y -> `List (`Int x :: [Custom_types.transition_output_type_to_yojson y])) trans.arrival_places trans.arrival_links);]
      
end;;


(*************************************************************************
				   protéine
		      				  réseau de Petri entier *)


module Proteine =
struct
  type t =
    {mol : molecule;
     transitions : Transition.t array;
     places : Place.t array;
     mutable launchables : int list;
     message_receptors_book : (string, int) BatMultiPMap.t ;
     handles_book : (string, int) BatMultiPMap.t ;
     mol_catchers_book : (string, int) BatMultiPMap.t ;}
      
    
  let get_launchables (ts : Transition.t array) =
    let t_l = ref [] in 
    for i = 0 to Array.length ts -1 do
      if Transition.launchable ts.(i)
      then t_l := i :: !t_l
      else ()
    done; !t_l
    
  let make (mol : molecule) : t = 
  (* liste des signatures des transitions *)
    let transitions_signatures_list = build_transitions mol
  (* liste des signatures des places *)
    and places_signatures_list = build_nodes_list mol
  in
(* on crée de nouvelles places à partir de 
   la liste de types données dans la molécule*)
    let places_list : Place.t list = 
      List.map 
	(fun x -> Place.make x)
	places_signatures_list
	
    in 
    let (places : Place.t array) = Array.of_list places_list
    in
    let (transitions_list : Transition.t list) = 
      List.map 
	(fun x -> let s, ila, ola = x in
		  Transition.make places ila ola)
	transitions_signatures_list
	
    in 
    let (transitions : Transition.t array) = 
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
	   BatMultiPMap.create compare (-), 
	   BatMultiPMap.create compare (-), 
	   BatMultiPMap.create compare (-)
	 )
    in 
    let (message_receptors_book, mol_catchers_book, handles_book) = 
      create_books places_signatures_list 0
    in 
    {mol; transitions; places; launchables = (get_launchables transitions);
     message_receptors_book; handles_book; mol_catchers_book;}


      
  (* mettre à jour les transitions qui peuvent être lancées.
     Il faut prendre en compte la transition qui vient d'être lancée, 
     ainsi que les tokens qui ont pu arriver par message 

     (du coup, faire plus efficace devient un peu du bazar)
     on peut faire beaucoup plus efficace, mais pour l'instant 
     on fait au plus simple *)
  let update_launchables p =
    p.launchables <- get_launchables p.transitions



  let launch_transition (tId : int) p : return_action list= 
    let initialTokens =
      List.fold_left 
	(fun l x ->
	  let token = Place.pop_token p.places.(x) in
	  token :: l)
	[] p.transitions.(tId).Transition.departure_places
    in 
    let finalTokens =
      Transition.transition_function initialTokens p.transitions.(tId)
    in
    BatList.map2
      (fun token place_id ->
	Place.add_token_from_transition token p.places.(place_id))
      finalTokens p.transitions.(tId).Transition.arrival_places
      
  let launch_random_transition p : return_action list =
    if not (p.launchables = [])
    then 
      let t = random_pick_from_list p.launchables in
      launch_transition t p
    else []

      
  (* relaie le message aux places concernées, créant ainsi
     des tokens quand c'est possible *)
  let send_message (m : string) (p : t) = 
    BatSet.PSet.iter 
      (fun x -> Place.add_token_from_message p.places.(x)) 
      (BatMultiPMap.find m p.message_receptors_book)

  let bind_mol (m : molecule)  (pat : string) (p : t) : bool = 
    let targets = BatMultiPMap.find pat p.mol_catchers_book in
    let bindSiteId = Misc_library.random_pick_from_PSet targets in
    Place.add_token_from_binding m p.places.(bindSiteId)


      (* il manque les livres, on verra plus tard, 
	 c'est déjà pas mal *)
  let to_json (p : t) =
    `Assoc [
      "places",
      `List (Array.to_list (Array.map Place.to_json p.places));
      "transitions",
      `List (Array.to_list (Array.map Transition.to_json p.transitions));
      "molecule",
      molecule_to_yojson p.mol;
      "launchables",
      `List (List.map (fun x -> `Int x) p.launchables);]

  let to_json_update (p:t) =
    `Assoc [
      "places",
      `List (Array.to_list (Array.map Place.to_json p.places));
      "launchables",
      `List (List.map (fun x -> `Int x) p.launchables);]

      
end;;


(*   examples de molecules et proteines test *)


let mol1 = [Node Initial_place];;
let prot1 = Proteine.make mol1;;

let mol2 = [Node Initial_place; Node Regular_place; TransitionInput ("a", Regular_ilink); TransitionOutput ("a", Regular_olink); Node Regular_place];;
let prot2 = Proteine.make mol2;;
