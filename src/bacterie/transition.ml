open Molecule
open Proteine.Proteine
open Proteine
open Place
open Token
open Misc_library
open Acid_types
   
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


  type t =
    {
      places : Place.t array;
      input_arcs : (int * AcidTypes.transition_input_type) list;
      output_arcs : (int * AcidTypes.transition_output_type) list;
    }
    
(* ** launchable function *)
(* Tells whether a given transition can be launched, *)
(* i.e. checks whether *)
(*  - departure places contain a token *)
(*  - filtering input_arcs have a token with the right label *)
(*  - arrival places are token-free *)

let launchable (transition : t) =
  let launchable_input_link  
        (input_link : AcidTypes.transition_input_type)
        (place : Place.t) =
    match input_link with
    | AcidTypes.Filter_ilink s ->
       begin
         match place.Place.tokenHolder with
         | Place.EmptyHolder -> false
         | Place.OccupiedHolder token ->
            s = Token.get_label token
       end
    | _ ->
       match place.Place.tokenHolder with
       | Place.EmptyHolder -> false
       | Place.OccupiedHolder token -> true
  and launchable_output_link  
        (output_link : AcidTypes.transition_output_type)
        (place : Place.t) =
    Place.is_empty place
  in
  List.fold_left
    (fun res (p_id, t_i) -> res && launchable_input_link t_i (transition.places.(p_id)))
    true
    transition.input_arcs
  &&
    List.fold_left
      (fun res (p_id, t_o) -> res && launchable_output_link t_o (transition.places.(p_id)))
      true
      transition.output_arcs
    

(* ** make function       *)
(* Creates a transition structure *)

    
  let make (places : Place.t array)
           (input_arcs : (int * AcidTypes.transition_input_type) list)
           (output_arcs : (int * AcidTypes.transition_output_type) list) =

    {places; input_arcs; output_arcs}
          
(* ** apply_transition function *)
(* Applique la fonction de transition d'une transition à une liste de tokens.  *)

(* La fonction apply_transitions_input parcourt la liste des (place*transitions d'entrée), on prend le token de la place et on applique éventuellement les split. Ça nous donne une liste de token, qu'on donne à manger à la fonction apply_transition_outputs. *)
(* Cette fonction parcourt la liste des (place * transition de sortie), et leur donne un token (éventuellement en combinant deux token pour un bind). *)

(* Du coup, certaines places d'arrivée peuvent ne pas reçevoir de token, *)
(* ou certains token peuvent être perdus. On va dire pour l'instant que *)
(* ce n'est pas grave, et que c'est au bactéries de gérer tout ça. *)

  type transition_effect =
    | Message_effect of string
    | Release_effect of Molecule.t
                      
let apply_transition (transition : t) : transition_effect list=
  let rec apply_transition_inputs
            (i_arc_l :
               (Place.t * AcidTypes.transition_input_type) list)
          : Token.t list =
    match i_arc_l with
    | (place, transi) :: i_arc_l' ->
       begin
         let token = Place.pop_token_for_transition place in
         match transi with
         | AcidTypes.Split_ilink  -> 
            let token1, token2 = Token.cut_mol token in
            token1 :: token2 ::
              apply_transition_inputs i_arc_l' 
         | _ -> token :: apply_transition_inputs i_arc_l'
       end
    | [] -> []
    and apply_transition_outputs 
          (o_arc_l :
             (Place.t * AcidTypes.transition_output_type) list)
          (tokens : Token.t list) :
          transition_effect list =

      match o_arc_l, tokens with
      | (place, AcidTypes.Bind_olink) :: o_arc_l',
        t1 :: t2 :: tokens' ->
         Place.add_token_from_transition (Token.insert t1 t2) place;
         apply_transition_outputs o_arc_l' tokens'
      | (place, AcidTypes.Release_olink) :: o_arc_l',
        token :: tokens' ->
         if Token.is_empty token
         then apply_transition_outputs o_arc_l' tokens'
         else Release_effect (Token.get_mol token) ::
                (apply_transition_outputs o_arc_l' tokens')
      | (place, AcidTypes.Regular_olink) :: o_arc_l',
        token :: tokens' ->
         Place.add_token_from_transition token place;
         apply_transition_outputs o_arc_l' tokens'
      | _ -> []
  in
  let i_arc_l = List.map
                  (fun (pid, t) -> transition.places.(pid),t)  
                  transition.input_arcs
  and o_arc_l = List.map
                  (fun (pid, t) -> transition.places.(pid),t)  
                  transition.output_arcs
  in apply_transition_outputs
       o_arc_l
       (apply_transition_inputs i_arc_l)

(* ** to_json function*)
  let to_json (trans : t) : Yojson.Safe.json =
    `Assoc [
       "input_arcs",
       `List (List.map
                (fun (x,y) -> `Assoc [("place", `Int x); ("type", AcidTypes.transition_input_type_to_yojson y)])
                trans.input_arcs);
       "output_arcs", 
       `List (List.map
                (fun (x,y) -> `Assoc [("place", `Int x); ("type", AcidTypes.transition_output_type_to_yojson y)])
                trans.output_arcs);]
      
end;;
  
