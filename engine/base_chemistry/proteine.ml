(* * this file *)

(*   proteine.ml defines the basic properties of a proteine, some *)
(*   functions to help build a petri-net out of it and a module to help it *)
(*   get managed by a petri-net (i.e. simulate chemical reactions *)

(* * preamble : load libraries *)

(* next lines are used when compiling in a ocaml toplevel *)
(* #directory "../../_build/src/libs" *)
(* #load "misc_library.ml" *)

(*open Misc_library*)

open Chemistry_types.Acid_types
(* open Yaac_config *)
open Local_libs
open Easy_logging_yojson
(* * Proteine module *)

let logger = Logging.make_logger "Yaac.Base_chem.Proteine"


(* * A proteine *)
type t = acid list
[@@deriving show, yojson]


(* *** transition structure type definition *)

(*     Structure utilisée pour stocker une transition. *)
(*     Triplet contenant : *)
(*       - une string, l'identifiant de la transition *)
(*       - une liste int*transInputType , dont chaque item contient *)
(*       l'entier correspondant au nœud d'où part la transistion, *)
(*       et le type de la transition *)
(*       - de même pour les arcs sortants *)

type transition_structure =
  string *
  (int * input_arc ) list *
  (int * output_arc) list
[@@deriving show]
(* *** place extensions definition *)

type place_extensions =
  extension list
[@@deriving show]

(* ** functions definitions *)
(* *** build_transitions function *)

(*     This function builds the transitions defined by the acides of a *)
(*     proteine. This will be used when folding the proteine to get *)
(*     functional form. *)
(*     On retourne une liste contenant les items (transID, *)
(*     transitionInputs, transitionOutputs) *)

(*     Algo : on parcourt les acides de la molécule, en gardant en *)
(*     mémoire l'id du dernier nœud visité. Si on tombe sur un acide *)
(*     contenant une transition, on parcourt la liste des transitions *)
(*     déjà créées pour voir si des transitions avec la même id ont déjà *)
(*     été traitées, auquel cas on ajoute cette transition à la *)
(*     transition_structure correspondante, et sinon on créée une *)
(*     nouvelle transition_structure *)

(*     Idées pour améliorer l'algo : *)
(*       - utiliser une table d'associations  (pour accélerer ?) *)
(*       - TODO : faire attention si plusieurs arcs entrants ou sortant *)
(*       correspondent au même nœud et à la même transition, auquel cas ça *)
(*       buggerait *)


(*     Problème : *)
(*     Que se passe-t-il si plusieurs transtions input avec la même id *)
(*     partent d'un même nœud, en particulier *)
(*     pour la gestion des token ? *)
(*     Plusieurs pistes : *)
(*       - [ ] la transition n'est pas crée *)
(*       - [X] seul un des arcs est pris en compte *)
(*       - [ ] le programme bugge -> *pas bon* *)
(*       - [ ] la transition est plus probable *)

(*     Idée de variant :  *)
(*     les arcs/extensions placés avant la première place sont associés *)
(*     avec la dernière. *)


let build_transitions (prot : t) :
  transition_structure list =

  (* insère un arc entrant dans la bonne transition
     de la liste des transitions *)
  let rec insert_new_input
      (nodeN :   int)
      (transID : string)
      (data :    input_arc)
      (transL :  transition_structure list) :

    transition_structure list =

    match transL with
    | (t, input, output) :: transL' ->
      if nodeN >= 0
      then
        if transID = t
        then (t,  (nodeN, data) :: input, output) :: transL'
        else (t, input, output) ::
             (insert_new_input nodeN transID data transL')
      else (insert_new_input nodeN transID data transL')
    | [] -> [transID, [nodeN, data], []]


  (* insère un arc sortant dans la bonne transition
     de la liste des transitions *)
  and insert_new_output
      (nodeN :   int)
      (transID : string)
      (data :    output_arc)
      (transL :  transition_structure list) :

    transition_structure list =

    match transL with
    | (t, input, output) :: transL' ->
      if nodeN >= 0
      then
        if transID = t
        then (t,  input, (nodeN, data) ::  output) :: transL'
        else (t, input, output) ::
             (insert_new_output nodeN transID data transL')
      else (insert_new_output nodeN transID data transL')
    | [] -> [transID, [], [nodeN, data]]

  in
  let rec aux
      (prot :    t)
      (nodeN :  int)
      (transL : transition_structure list) :

    transition_structure list =

    match prot, nodeN with
    | Place :: prot', _ -> aux prot' (nodeN + 1) transL
    | _::prot', -1 -> aux prot' nodeN transL
    | InputArc (s,d) :: prot',_ ->
      aux prot' nodeN (insert_new_input nodeN s d transL)

    | OutputArc (s,d) :: prot',_ ->
      aux prot' nodeN (insert_new_output nodeN s d transL)

    | Extension _ :: prot' ,_-> aux prot' nodeN transL
    | [],_ -> transL

  in aux prot (-1) []


(* *** build_nodes_list_with_exts function *)
(*     Construit la liste des nœuds avec les extensions associée  *)
(*     (inversant ainsi l'ordre de la liste des nœuds). *)
(*     L'ordre est ensuite reinversé, sinon la liste des places est  *)
(*     inversé dans la protéine. *)

let build_nodes_list_with_exts (prot : t) :
  ((extension list)) list =

  let rec aux prot res =
    match prot with
    | Place :: prot' -> aux prot' (([]) :: res)
    | Extension e :: prot' ->
      begin
        match res with
        | [] -> aux prot' res
        | (ext_l) :: res' ->
          aux prot' ((e :: ext_l) :: res')
      end
    | _ :: prot' -> aux prot' res
    | [] -> res
  in
  List.rev (aux prot [])


(* wonderfull tail-recursive all-in-one function*)


module Tmap = CCMap.Make(String)
let rec build_data (prot : t)
    (trans : ((int*input_arc) list *
              (int*output_arc) list) Tmap.t)
    (places : (int * extension list) list)
  =
  match places with
  | (n, exts) :: places' ->
    (
      match prot with
      | Place ::prot' ->
        build_data prot' trans ((n+1,[])::places)

      | InputArc (id, t) :: prot' ->
        build_data prot'

          (Tmap.update id
             (fun item ->
                match item with
                | None -> Some ([],[])
                | Some (ias, oas) ->
                  Some ((n, t)::ias, oas))
             trans)
          places

      | OutputArc (id, t) ::prot' ->
        build_data prot'
          (Tmap.update id
             (fun item ->
                match item with
                | None -> Some ([],[])
                | Some (ias, oas) ->
                  Some (ias, (n, t)::oas))
             trans)
          places

      | Extension e :: prot' ->
        build_data prot' trans ((n, e::exts)::places')

      | [] -> trans, places
    )
  | [] ->
    match prot with
    | Place ::prot' ->
      build_data prot'  trans ((0,[])::[])
    | _ ::prot'->
      build_data prot' trans places
    | [] -> trans, places
