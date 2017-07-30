
open Molecule.Molecule
open Molecule
open Place

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
    let places_are_occupied
          (places :  Place.t array) (to_try : int list): bool =

      List.fold_left
        (fun res pId -> (not (Place.is_empty places.(pId))) && res )
        true to_try
    and places_are_free
          (places :  Place.t array) (to_try : int list): bool =

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
           : (Token.t list)   =
     
     match tokens with
     | [] -> []
     | token :: tokens' ->
        if Token.is_empty token
        then input_transition_function (List.tl ill) tokens'
        else
          match ill with
          | []  -> []
          | AcidTypes.Regular_ilink ::ill' -> 
             token ::  input_transition_function ill' tokens'
          | AcidTypes.Split_ilink :: ill' -> 
             let token1, token2 = Token.cut_mol token in
             token1 :: token2 :: input_transition_function ill' tokens'
             
   (* fonction qui prends une liste d'arcs entrants et une liste de molécukes, 
  et renvoie une liste de tokens  *)
   and  output_transition_function 
          (oll : AcidTypes.transition_output_type list)
          (tokens : Token.t list)
        : Token.t list =
     
     match oll with
     | AcidTypes.Regular_olink :: oll' -> 
        Token.empty :: output_transition_function oll'  tokens
     | AcidTypes.Bind_olink :: oll' -> 
        begin
          match tokens with
          | t1 ::  t2 :: tokens' ->
             (Token.insert t1 t2)
             :: output_transition_function oll' tokens'
          | t :: [] -> [t]
          | [] -> []
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
       `List (List.map2
                (fun x y -> `List (`Int x :: [AcidTypes.transition_output_type_to_yojson y]))
                trans.arrival_places trans.arrival_links);]
      
end;;
  
