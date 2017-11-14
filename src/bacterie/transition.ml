open Molecule
open Proteine.Proteine
open Proteine
open Place
open Token
open Misc_library
open Acid_types
   
(* * the transition module *)
(* Module to manage transitions :  *)
(* ** TODO Réécrire le module ? *)
(*    + soit mettre un pointeur vers le PNET *)
(*    + soit faire pointer les arcs directement  *)
(*      vers les places -> oui c'est bien, *)
(*      après il suffit des prendre les id des places  *)
(*      pour recréer la structure dans le client *)

module Transition =
struct

(* ** type d'une transition *)
(* Structure contenant : *)
(*  - la liste des places de la molécule (pour savoir si des token sont présents) *)
(*  - la liste des index des places de départ *)
(*  - la liste des pointeurs des places d'arrivée *)
(*  - la liste des types de transition entrantes *)
(*  - la liste des types de transitions sortantes *)

  type input_arc = {source_place : int;
                    iatype : AcidTypes.input_arc_type}
                     [@@ deriving yojson]
  type output_arc = {dest_place : int;
                     oatype : AcidTypes.output_arc_type;}
                      [@@ deriving yojson]
                  
  type t =
    {
      mutable launchable : bool;
      id : string;
      places : Place.t array;
      input_arcs :  input_arc list;
      output_arcs : output_arc list;
    }
      [@@ deriving yojson]
    
(* ** launchable function *)
(* Tells whether a given transition can be launched, *)
(* i.e. checks whether *)
(*  - departure places contain a token *)
(*  - filtering input_arcs have a token with the right label *)
(*  - arrival places are token-free *)

let launchable (transition : t) =
  let launchable_input_arc 
        (input_arc : AcidTypes.input_arc_type)
        (place : Place.t) =
    match input_arc with
    | AcidTypes.Filter_iarc s ->
       begin
         match place.Place.token with
         | No_token -> false
         | _ as token ->
            s = Token.get_label token
       end
    | _ ->
       not (Place.is_empty place)
  and launchable_output_arc  
        (output_arc : AcidTypes.output_arc_type)
        (place : Place.t) =
    Place.is_empty place
  in
  List.fold_left
    (fun res ia -> res && launchable_input_arc ia.iatype (transition.places.(ia.source_place)))
    true
    transition.input_arcs
  &&
    List.fold_left
      (fun res oa -> res && launchable_output_arc oa.oatype (transition.places.(oa.dest_place)))
      true
      transition.output_arcs
    
let update_launchable t : unit = 
  t.launchable <- launchable t
(* ** make function       *)
(* Creates a transition structure *)

    
let make (id : string)
         (places : Place.t array)
         (input_arcs : (int * AcidTypes.input_arc_type) list)
         (output_arcs : (int * AcidTypes.output_arc_type) list) =
  
  {launchable=false; id; places;
   input_arcs = List.map( fun (pid, t) -> {source_place = pid;
                                           iatype = t}) input_arcs;
   
   output_arcs = List.map( fun (pid, t) -> {dest_place = pid;
                                            oatype = t}) output_arcs;
  }
          
(* ** apply_transition function *)
(* Applique la fonction de transition d'une transition à une liste de tokens.  *)

(* La fonction apply_transitions_input parcourt la liste des (place*transitions d'entrée), on prend le token de la place et on applique éventuellement les split. Ça nous donne une liste de token, qu'on donne à manger à la fonction apply_output_arcs. *)
(* Cette fonction parcourt la liste des (place * transition de sortie), et leur donne un token (éventuellement en combinant deux token pour un bind). *)

(* Du coup, certaines places d'arrivée peuvent ne pas reçevoir de token, *)
(* ou certains token peuvent être perdus. On va dire pour l'instant que *)
(* ce n'est pas grave, et que c'est au bactéries de gérer tout ça. *)

  type transition_effect =
    | Message_effect of string
    | Release_effect of Molecule.t
                      
let apply_transition (transition : t) : transition_effect list=
  let rec apply_input_arcs
            (i_arc_l :
               (Place.t * AcidTypes.input_arc_type) list)
          : Token.t list =
    match i_arc_l with
    | (place, transi) :: i_arc_l' ->
       begin
         let token = Place.pop_token place in
         match transi with
         | AcidTypes.Split_iarc  -> 
            let token1, token2 = Token.cut_mol token in
            token1 :: token2 ::
              apply_input_arcs i_arc_l' 
         | _ -> token :: apply_input_arcs i_arc_l'
       end
    | [] -> []
    and apply_output_arcs 
          (o_arc_l :
             (Place.t * AcidTypes.output_arc_type) list)
          (tokens : Token.t list) :
          transition_effect list =

      match o_arc_l, tokens with
      | (place, AcidTypes.Bind_oarc) :: o_arc_l',
        t1 :: t2 :: tokens' ->
         Place.add_token_from_transition (Token.insert t1 t2) place;
         apply_output_arcs o_arc_l' tokens'
      | (place, AcidTypes.Release_oarc) :: o_arc_l',
        token :: tokens' ->
         if Token.is_empty token
         then apply_output_arcs o_arc_l' tokens'
         else Release_effect (Token.get_mol token) ::
                (apply_output_arcs o_arc_l' tokens')
      | (place, AcidTypes.Regular_oarc) :: o_arc_l',
        token :: tokens' ->
         Place.add_token_from_transition token place;
         apply_output_arcs o_arc_l' tokens'
      | _ -> []
  in
  let i_arc_l = List.map
                  (fun ia -> transition.places.(ia.source_place),ia.iatype)  
                  transition.input_arcs
  and o_arc_l = List.map
                  (fun oa -> transition.places.(oa.dest_place),oa.oatype)  
                  transition.output_arcs
  in apply_output_arcs
       o_arc_l
       (apply_input_arcs i_arc_l)

end;;
  
