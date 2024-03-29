(*open Misc_library*)

(* * the transition module *)
(* Module to manage transitions :  *)
(* ** TODO Réécrire le module ? *)
(*    + soit mettre un pointeur vers le PNET *)
(*    + soit faire pointer les arcs directement  *)
(*      vers les places -> oui c'est bien, *)
(*      après il suffit des prendre les id des places  *)
(*      pour recréer la structure dans le client *)

(* ** type d'une transition *)
(* Structure contenant : *)
(*  - la liste des places de la molécule (pour savoir si des token sont présents) *)
(*  - la liste des index des places de départ *)
(*  - la liste des pointeurs des places d'arrivée *)
(*  - la liste des types de transition entrantes *)
(*  - la liste des types de transitions sortantes *)
open Local_libs.Numeric
open Local_libs

let logger = Jlog.make_logger "Yaac.Base_chem.Transition"

include Types.Transition
(* ** launchable function *)
(* Tells whether a given transition can be launched, *)
(* i.e. checks whether *)
(*  - departure places contain a token *)
(*  - filtering input_arcs have a token with the right label *)
(*  - arrival places are token-free *)

let launchable (transition : t) places =
  if
    List.length transition.output_arcs = 0
    || List.length transition.input_arcs = 0
  then false
  else
    let launchable_input_arc (input_arc : Types.Acid.input_arc)
        (place : Place.t) =
      match input_arc with
      | Types.Acid.Filter_iarc s -> (
          match place.Place.token with
          | None -> false
          | Some token -> s = Token.get_label token)
      | Types.Acid.Filter_empty_iarc -> (
          match place.Place.token with
          | None -> false
          | Some token -> Token.get_label token = "")
      | Types.Acid.No_token_iarc -> (
          match place.Place.token with None -> true | Some _ -> false)
      | _ -> not (Place.is_empty place)
    and launchable_output_arc (output_arc : Types.Acid.output_arc)
        (place : Place.t) =
      Place.is_empty place
      || (* we test if the place is in the source places, to allow cycle transitions *)
      List.exists
        (fun { source_place = sp; iatype = _ } -> place.index = sp)
        transition.input_arcs
    in
    List.fold_left
      (fun res ia ->
        res && launchable_input_arc ia.iatype places.(ia.source_place))
      true transition.input_arcs
    && List.fold_left
         (fun res oa ->
           res && launchable_output_arc oa.oatype places.(oa.dest_place))
         true transition.output_arcs

let update_launchable transition places : unit =
  transition.launchable <- launchable transition places
(* ** make function       *)
(* Creates a transition structure *)

let make (id : string) (places : Place.t array)
    (input_arcs : (int * Types.Acid.input_arc) list)
    (output_arcs : (int * Types.Acid.output_arc) list) (index : int) : t =
  let t =
    {
      launchable = false;
      id;
      input_arcs =
        List.map (fun (pid, t) -> { source_place = pid; iatype = t }) input_arcs;
      output_arcs =
        List.map (fun (pid, t) -> { dest_place = pid; oatype = t }) output_arcs;
      index;
    }
  in
  update_launchable t places;
  t

(* ** apply_transition function *)
(* Applique la fonction de transition d'une transition à une liste de tokens.  *)

(* La fonction apply_transitions_input parcourt la liste des (place*transitions d'entrée), on prend le token de la place et on applique éventuellement les split. Ça nous donne une liste de token, qu'on donne à manger à la fonction apply_output_arcs. *)
(* Cette fonction parcourt la liste des (place * transition de sortie), et leur donne un token (éventuellement en combinant deux token pour un merge). *)

(* Du coup, certaines places d'arrivée peuvent ne pas reçevoir de token, *)
(* ou certains token peuvent être perdus. On va dire pour l'instant que *)
(* ce n'est pas grave, et que c'est au bactéries de gérer tout ça. *)

let apply_transition (transition : t) places : Place.transition_effect list =
  let rec apply_input_arcs (i_arc_l : (Place.t * Types.Acid.input_arc) list) :
      Token.t list =
    match i_arc_l with
    | (_, No_token_iarc) :: i_arc_l' -> apply_input_arcs i_arc_l'
    | (place, transi) :: i_arc_l' -> (
        let token = Place.pop_token place in
        match transi with
        | Types.Acid.Split_iarc ->
            let token1, token2 = Token.cut_mol token in
            token1 :: token2 :: apply_input_arcs i_arc_l'
        | _ -> token :: apply_input_arcs i_arc_l')
    | [] -> []
  and apply_output_arcs (o_arc_l : (Place.t * Types.Acid.output_arc) list)
      (tokens : Token.t list) : Place.transition_effect list =
    (* TODO : permettre au merge de ne prendre qu'un token
       (et donc de   ne pas avoir d'effet ?) *)
    match (o_arc_l, tokens) with
    | (place, Types.Acid.Merge_oarc) :: o_arc_l', t1 :: t2 :: tokens' ->
        let effects =
          Place.add_token_from_transition (Token.insert t1 t2) place
        in
        effects @ apply_output_arcs o_arc_l' tokens'
    | (place, Types.Acid.Move_oarc move_dir) :: o_arc_l', token :: tokens' ->
        let new_token =
          if move_dir then Token.move_mol_forward token
          else Token.move_mol_backward token
        in
        let effects = Place.add_token_from_transition new_token place in
        effects @ apply_output_arcs o_arc_l' tokens'
    | (place, Types.Acid.Regular_oarc) :: o_arc_l', token :: tokens' ->
        let effects = Place.add_token_from_transition token place in
        effects @ apply_output_arcs o_arc_l' tokens'
    (* TODO : ajouter des release effect aux tokens restants *)
    | _ -> []
  in
  let i_arc_l =
    List.map
      (fun ia -> (places.(ia.source_place), ia.iatype))
      transition.input_arcs
  and o_arc_l =
    List.map
      (fun oa -> (places.(oa.dest_place), oa.oatype))
      transition.output_arcs
  in
  apply_output_arcs o_arc_l (apply_input_arcs i_arc_l)
