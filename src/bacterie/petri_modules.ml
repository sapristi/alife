
open Misc_library
open Molecule

(* * the token module *)
   
(* Molecules are transformed into proteines by compiling them into a petri net. We define here the tokens used in the petri nets. Tokens go through transitions, and can hold a molecule on which actions will be performed by the transitions, simulating chemical reactions. *)

(* il faudrait faire attention aux molécules vides (ie liste vide, et peut-être transformer les tokens qui contiennent une molécule vide en token vide (mais pas sûr) *)

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



(* * the place module *)

(* ** the return_action type :deprecated: *)
(* Used to describe the action taken when a token goes to a place after transiting through a transition. Determined by the type of the place.  *unfinished feature* *)
(* Ne va à priori plus servir : les places ont une liste d'extensions qui peuvent chacune avoir des effets de bord, qu'on applique à réception d'un token *)

type return_action =
  | AddMol of MoleculeHolder.t
  | SendMessage of string
  | NoAction
      [@@deriving show]

(* ** the place module *)
(*    Module qui gère les places. Une place a un type, et peut contenir un jeton.  *)

module Place =
  struct

(* *** divers *)

    type token_holder = EmptyHolder | OccupiedHolder of Token.t
      [@@deriving show]

    let token_holder_to_json (th : token_holder) : Yojson.Safe.json =
      match th with
      | EmptyHolder -> `String "no token"
      | OccupiedHolder t -> Token.to_json t

    type place_exts = AcidTypes.extension_type list;;
    type t =
      {mutable tokenHolder : token_holder;
       placeType : AcidTypes.place_type;
       extensions : AcidTypes.extension_type list}
        [@@deriving show]
(* **** make a place *)
(* ***** DONE allow place extension to initialise the place with an empty token *)

    let make (place_with_exts : AcidTypes.place_type *  place_exts) : t =
      let placeType, extensions = place_with_exts in
      if List.mem AcidTypes.Init_with_token extensions
      then {tokenHolder = OccupiedHolder Token.empty; placeType;extensions}
      else {tokenHolder = EmptyHolder; placeType;extensions}
      
    let is_empty (p : t) : bool =
      p.tokenHolder = EmptyHolder
      
    let remove_token (p : t) : unit=
      p.tokenHolder <- EmptyHolder
      
    let set_token (token : Token.t) (p : t) : unit =
      p.tokenHolder <- OccupiedHolder token
      
  

(* *** Token reçu d'une transition. :deprecated:  *)
(*     Il faut appliquer les effets de bord suivant le type de place. on va écrire une autre fonction qui traite les extensions *)
    
(*
let add_token_from_transition_deprecated (inputToken : Token.t) (p : t) : return_action=
  if is_empty p
  then 
    match p.placeType with
      
    (* il faut dire à l'host qu'on a  relaché la molecule attachée au token.
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
 *)


(* *** Token reçu d'une transition. *)
(* **** TODO ajouter les effets de bords générés par les extensions *)
let add_token_from_transition (inputToken : Token.t) (place : t) =
  set_token inputToken place;;
(* *** Token ajouté par un broadcast de message. *)
(*    Il faudrait peut-être bien vérifier que la place reçoit des messages, que le message correspond, tout ça tout ça *)

let add_token_from_message (p : t) : unit =
  if is_empty p
  then set_token Token.empty p

(* *** token ajouté quand on attrape une molécule *)
(*on renvoie un booléen pour faire remonter facilement si le binding était possible ou pas *)
let add_token_from_binding (mol : Molecule.molecule) (p : t) : bool =
    if is_empty p
    then
      ( set_token (Token.make (MoleculeHolder.make mol)) p;
        true )
    else
      false
    
(* *** remove the token from tokenHolder *)
  let pop_token (p : t) : Token.t =
    match p.tokenHolder with
    | EmptyHolder -> failwith "cannot pop token from empty place"
    | OccupiedHolder token ->
       ( remove_token p;
         token )

(* **** get_msg_receivers *)
  let rec get_msg_receivers (p : t) : AcidTypes.msg_format list =
    let rec aux exts = 
    match exts with
    | [] -> []
    | AcidTypes.Receive_msg_ext msg :: exts' -> msg :: aux exts'
    | _ :: exts' -> aux exts'
    in
    aux p.extensions

(* **** get_mol_catchers *)
  let get_catchers (p : t) : AcidTypes.catch_pattern list =
    let rec aux exts =
      match exts with
      | [] -> []
      | AcidTypes.Catch_ext cp :: exts' -> cp :: aux exts'
    | _ :: exts' -> aux exts'
    in
    aux p.extensions
                                    
      
(* *** to_json *)
  let to_json (p : t) =
    `Assoc [("token", token_holder_to_json p.tokenHolder); ("type", AcidTypes.place_type_to_yojson p.placeType)]
end;;

(* * the transition module *)
(* Module to manage transitions :  *)

module Transition =
struct

(* ** type d'une transition *)
(* Structure contenant : *)
(*  - la liste des places de la molécule (pour savoir si des token sont présents) *)
(*  - la liste des index des places de départ *)
(*  - la liste des pointeurs des places d'arrivée *)
(*  - la liste des types de transition entrantes *)
(*  - la liste des types de transitions sortantes *)

  type t  =
    {places : Place.t array;
     departure_places : int list;
     arrival_places : int list;
     departure_links : AcidTypes.transition_input_type list;
     arrival_links : AcidTypes.transition_output_type list;
    }
      [@@deriving show]


(* ** launchable function *)
(* Tells whether a given transition can be launched,  *)
(* i.e. checks whether *)
(*  - departure places contain a token *)
(*  - arrival places are token-free *)
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
      
(* ** make function       *)
(* Creates a transition structure *)

  let make (places : Place.t array)
      (depL : (int * AcidTypes.transition_input_type) list)
      (arrL : (int * AcidTypes.transition_output_type) list) =
  let departure_places, departure_links = unzip depL and 
      arrival_places, arrival_links = unzip arrL 
  in {places; departure_places; arrival_places;
      departure_links; arrival_links;}

(* ** transition_function function *)
(* Applique la fonction de transition d'une transition à une liste de tokens. *Ça a l'air particulièrement écrit à l'arrach, il va sûrement falloir tout réécrire. *)

(* On parcourt la liste des token donnés en entrée (qu'on suppose être ceux contenus dans les places de départ), si le token contient une molécule on pop la liste des input_link, et si c'est un split_link, on coupe la molécule -> ça n'a pas du tout l'air de faire la bonne correspondante entre la place d'où vient le token et le lien correspondant. *)

   
let transition_function (inputTokens : Token.t list) (transition : t) =
    
(* fonction qui prends une liste d'arcs entrants et une liste de tokens,
et calcule  la liste des molécules des tokens (qui ont potentiellement 
                                                   été coupées *)
   let rec input_transition_function 
             (ill : AcidTypes.transition_input_type list)
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
           | AcidTypes.Regular_ilink ::ill' -> 
              mol ::  input_transition_function ill' tokens'
           | AcidTypes.Split_ilink :: ill' -> 
              let mol1, mol2 = MoleculeHolder.cut mol in
          mol1 :: mol2 :: input_transition_function ill' tokens'
              
   (* fonction qui prends une liste d'arcs entrants et une liste de molécukes, 
  et renvoie une liste de tokens  *)
   and  output_transition_function 
          (oll : AcidTypes.transition_output_type list)
          (mols : MoleculeHolder.t list)
        : Token.t list =
     
     match oll with
     | AcidTypes.Regular_olink :: oll' -> 
        Token.empty :: output_transition_function oll'  mols
     | AcidTypes.Bind_olink :: oll' -> 
        begin
          match mols with
          | m1 ::  m2 :: mols' -> 
             (Token.make (MoleculeHolder.insert m1 m2)) :: output_transition_function oll' mols
          | m :: [] -> 
             Token.make m  :: output_transition_function oll'  mols          
          | [] -> 
             Token.empty :: output_transition_function oll' mols
        end
       
     | [] -> []
           
   in
   
   output_transition_function
     transition.arrival_links
     (input_transition_function
        transition.departure_links
        inputTokens)

(* ** to_json function*)
  let to_json (trans : t) : Yojson.Safe.json =
    `Assoc [
       "dep_places",
       `List (List.map2
                (fun x y -> `List (`Int x :: [AcidTypes.transition_input_type_to_yojson y]))
                trans.departure_places trans.departure_links);
       "arr_places", 
       `List (List.map2 (fun x y -> `List (`Int x :: [AcidTypes.transition_output_type_to_yojson y])) trans.arrival_places trans.arrival_links);]
      
end;;
  
