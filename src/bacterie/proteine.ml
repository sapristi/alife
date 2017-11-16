(* * this file *)
  
(*   proteine.ml defines the basic properties of a proteine, some *)
(*   functions to help build a petri-net out of it and a module to help it *)
(*   get managed by a petri-net (i.e. simulate chemical reactions *)

(* * preamble : load libraries *)

(* next lines are used when compiling in a ocaml toplevel *)
(* #directory "../../_build/src/libs" *)
(* #load "misc_library.ml" *)

open Misc_library
open Batteries
open Molecule
open Graber



(* * defining types for acids *)
(* ** description générale :in_progress: *)
(*    Implémentation des types différents acides. Voilà en gros l'organisation : *)
(*   + place : aucune fonctionalité *)
(*   + transition : agit sur la molécule contenue dans un token *)
(*     - regular : rien de particulier *)
(*     - split : coupe une molécule en 2 (seulement transition_input) *)
(*     - bind : insère une molécule dans une autre (seulement transition_output) *)
(*     - release : supprime le token, et relache l'éventuelle molécule *)
(*       contenue dans celui-ci *)
(*   + extension : autres ? *)
(*     - handle : poignée pour attraper cette molécule *)
(*       problème : il faudrait pouvoir attrapper la molécule à n'importe quel acide ? ou alors on attrappe la poignée directement et pas la place associée *)
(*     - catch : permet d'attraper une molécule. *)
(*       Est ce qu'il y a une condition d'activation, par exemple un token vide (qui contiendrait ensuite la molécule) ? *)
(*     - release : lache la molécule attachée -> plutot dans les transitions *)
(*     - move : déplace le point de contact de la molécule *)
(*     - send : envoie un message *)
(*     - receive : receives a message *)

(*   Questions : est-ce qu'on met l'action move sur les liens ou en *)
(*   extension ? dans les liens c'est plus cohérent, mais dans les *)
(*   extensions ça permet d'en mettre plusiers à la suite. Par contre, à *)
(*   quel moment est-ce qu'on déclenche l'effet de bord ? En recevant le *)
(*   token d'une transition.  Mais du coup pour l'action release, il *)
(*   faudrait aussi la mettre sur les places, puisqu'on agit aussi à *)
(*   l'extérieur du token. Du coup pour l'instant on va mettre à la fois *)
(*   move et release dans les extensions, avec un système pour appliquer *)
(*   les effets des extensions quand on reçoit un token. *)

(*   L'autre question est, comment appliquer les effets de bord qui *)
(*   affectent la bactérie ? *)
(*   Le plus simple est de mettre les actions ayant de tels effets de bord *)
(*   sur les transitions, donc send_message et release_mol seront sur *)
(*   les olink *)
  
(* ** implémentation *)
              
module AcidTypes =
  struct
(* *** place *)
    type place_type = Regular_place
                          [@@deriving yojson]
    
(* *** transition_input *)
    type input_arc_type = 
      | Regular_iarc
      | Split_iarc
      | Filter_iarc of string
                          [@@deriving yojson]
                      
(* *** transition_output *)
    type output_arc_type = 
      | Regular_oarc
      | Bind_oarc
      | Move_oarc of bool
[@@deriving yojson]



(* *** extension *)
(* Types used by the extensions. Usefull to use custom types for easier potential changes later on.  *)

                    
    type extension_type =
      | Grab_ext of Graber.t
      | Release_ext
      | Init_with_token_ext
[@@deriving yojson]
      
      
(*
      | Displace_mol_ext of bool
      | Handle_ext of handle_id
      | Catch_ext of bind_pattern
      | Information_ext of string
 *)                         
(* ** type definitions *)
(* *** acid type definition *)
(*     We define how the abstract types get combined to form functional  *)
(*     types to eventually create petri net *)
(*       + Node : used as a token placeholder in the petri net *)
(*       + TransitionInput :  an incomming edge into a transition of the  *)
(*       petri net *)
(*       + a transition output : an outgoing edge into a transition of the  *)
(*       petri net *)
(*       + a piece of information : ???? *)

      
    type acid = 
      | Place
      | InputArc of string * input_arc_type
      | OutputArc of string * output_arc_type
      | Extension of extension_type
                       [@@deriving yojson]
                   
                         
  end;;




   
(* * Proteine module *)
module Proteine = 
  struct 
    
    open AcidTypes

(* * A proteine *)                   
    type t = acid list
                  [@@deriving yojson]
                
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
    (int * AcidTypes.input_arc_type ) list * 
      (int * AcidTypes.output_arc_type) list

(* *** place extensions definition *)

  type place_extensions =
    AcidTypes.extension_type list
    
(* ** functions definitions *)
(* *** build_transitions function *)

(*     This function builds the transitions defined by the acides of a *)
(*     proteine. This will be used when folding the proteine to get  *)
(*     functional form. *)
(*     On retourne une liste contenant les items (transID, *)
(*     transitionInputs, transitionOutputs) *)

(*     Algo : on parcourt les acides de la molécule, en gardant en  *)
(*     mémoire l'id du dernier nœud visité. Si on tombe sur un acide  *)
(*     contenant une transition, on parcourt la liste des transitions  *)
(*     déjà créées pour voir si des transitions avec la même id ont déjà  *)
(*     été traitées, auquel cas on ajoute cette transition à la  *)
(*     transition_structure correspondante, et sinon on créée une  *)
(*     nouvelle transition_structure *)

(*     Idées pour améliorer l'algo : *)
(*       - utiliser une table d'associations  (pour accélerer ?) *)
(*       - TODO : faire attention si plusieurs arcs entrants ou sortant  *)
(*       correspondent au même nœud et à la même transition, auquel cas ça  *)
(*       buggerait *)

let build_transitions (prot : t) :
      transition_structure list = 
  
  (* insère un arc entrant dans la bonne transition 
   de la liste des transitions *)
  let rec insert_new_input 
            (nodeN :   int) 
            (transID : string) 
            (data :    AcidTypes.input_arc_type) 
            (transL :  transition_structure list) : 
            
            transition_structure list =
  
    match transL with
    | (t, input, output) :: transL' -> 
       if transID = t 
       then (t,  (nodeN, data) :: input, output) :: transL'
       else (t, input, output) ::
              (insert_new_input nodeN transID data transL')
    | [] -> [transID, [nodeN, data], []]
        
        
(* insère un arc sortant dans la bonne transition 
   de la liste des transitions *)
  and insert_new_output 
        (nodeN :   int) 
        (transID : string)
        (data :    AcidTypes.output_arc_type) 
        (transL :  transition_structure list) :
        
      transition_structure list =  
    
    match transL with
    | (t, input, output) :: transL' -> 
       if transID = t 
       then (t,  input, (nodeN, data) ::  output) :: transL'
       else (t, input, output) ::
              (insert_new_output nodeN transID data transL')
    | [] -> [transID, [], [nodeN, data]]
          
  in 
  let rec aux 
            (prot :    t)
            (nodeN :  int) 
            (transL : transition_structure list) :
            
            transition_structure list = 
    
    match prot with
    | Place :: prot' -> aux prot' (nodeN + 1) transL
    | InputArc (s,d) :: prot' ->
       aux prot' nodeN (insert_new_input nodeN s d transL)

    | OutputArc (s,d) :: prot' ->
       aux prot' nodeN (insert_new_output nodeN s d transL)
      
    | Extension _ :: prot' -> aux prot' nodeN transL
    | [] -> transL
   
  in 
  aux prot (-1) []

(* *** build_nodes_list_with_exts function *)
(*     Construit la liste des nœuds avec les extensions associée  *)
(*     (inversant ainsi l'ordre de la liste des nœuds). *)
(*     L'ordre est ensuite reinversé, sinon la liste des places est  *)
(*     inversé dans la protéine. *)

  let build_nodes_list_with_exts (prot : t) :
        ((extension_type list)) list =
    
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
    
(* *** build books  *)
(* Functions used to build references to the handles, catchers and  *)
(* grabers of a molecule *)


let build_grabers_book (prot : t) : (Graber.t, int) BatMultiPMap.t =
  let rec aux  prot n map =
    match prot with
    | Place _ :: prot' -> aux prot' (n+1) map
    | Extension ext :: prot' ->
       if n >= 0
       then
         begin
           match ext with
           | AcidTypes.Grab_ext g ->
              aux prot' n (BatMultiPMap.add g n map)
           | _ -> aux  prot' n map
         end
       else
         aux prot' n map
    | _ :: prot' -> aux prot' n map
    | [] -> map
  in
  aux prot (-1) BatMultiPMap.empty



(* *** from_mol *)

(* reads a molecule (list of atoms) to build a proteine (list of acids) *)
(* An acid is usually depicted using a sequence of  3 atoms, with  *)
(* possible options encoded with a string following the sequence,  *)
(* ended with a D atom. *)

  let rec of_molecule (mol : Molecule.t) : t =
    match mol with
      
    | A::A::A::mol' -> (Place) :: of_molecule mol'
                     
    | B::A::A::mol' ->
       let s,mol'' = Molecule.extract_message mol' in
       (InputArc (s,Regular_iarc)) :: (of_molecule mol'')
       
    | B::B::A::mol' ->
       let s,mol'' = Molecule.extract_message mol' in
       (InputArc (s,Split_iarc)) :: (of_molecule mol'')
       
    | B::C::a::mol' ->
       let s,mol'' = Molecule.extract_message mol' in
       (InputArc (s,Filter_iarc (Atome.to_string a))) :: of_molecule mol''
       
    | C::A::A::mol'->
       let s,mol'' = Molecule.extract_message mol' in
       (OutputArc (s,Regular_oarc)) :: of_molecule mol''
       
    | C::B::A::mol'->
       let s,mol'' = Molecule.extract_message mol' in
       (OutputArc (s,Bind_oarc)) :: of_molecule mol''
       
    | C::C::A::mol'->
       let s,mol'' = Molecule.extract_message mol' in
       (OutputArc (s,Move_oarc true)) :: of_molecule mol''
       
    | C::C::B::mol'->
       let s,mol'' = Molecule.extract_message mol' in
       (OutputArc (s,Move_oarc false)) :: of_molecule mol''
       
    | D::D::A::mol'->
       (Extension Release_ext) :: of_molecule mol'
      
    | D::C::B::mol'->
       (Extension Init_with_token_ext) :: of_molecule mol'
      
    | D::D::C::mol' ->
       let s,mol'' = Molecule.extract_message_as_mol mol' in
       (Extension (Grab_ext (Graber.make  s))) :: of_molecule mol''
       
    | a :: mol' -> of_molecule mol'
    | [] -> []

(* *** to_molecule *)
(* inverse of the previous function *)          

  let rec to_molecule (prot : t) : Molecule.t =
    match prot with
    | Place :: prot' ->
       Atome.A::A::A::(to_molecule prot')
    | InputArc (s,Regular_iarc) :: prot' ->
       Atome.B::A::A::(Molecule.string_to_message_mol s)@(to_molecule prot')
    | InputArc (s,Split_iarc) :: prot' ->
       Atome.B::B::A::(Molecule.string_to_message_mol s)@(to_molecule prot')
    | InputArc (s,(Filter_iarc f)) :: prot' ->
       let a = Atome.of_char (f.[0]) in
       Atome.B::C::a::(Molecule.string_to_message_mol s)@(to_molecule prot')
    | OutputArc (s,Regular_oarc) :: prot' ->
         Atome.C::A::A::(Molecule.string_to_message_mol s)@(to_molecule prot')
    | OutputArc (s,Bind_oarc) :: prot' ->
       Atome.C::B::A::(Molecule.string_to_message_mol s)@(to_molecule prot')
    | OutputArc (s,Move_oarc true) :: prot' ->
       Atome.C::C::A::(Molecule.string_to_message_mol s)@(to_molecule prot')
    | OutputArc (s,Move_oarc false) :: prot' ->
       Atome.C::C::B::(Molecule.string_to_message_mol s)@(to_molecule prot')
    | Extension Release_ext :: prot' ->
       D::D::A::(to_molecule prot')
    | Extension Init_with_token_ext :: prot' ->
       D::C::B::(to_molecule prot')
    | Extension (Grab_ext g) :: prot' ->
      D::D::C::((g.raw)@[Atome.F;F;F]@(to_molecule prot'))
      
    | [] -> []
          

end;;

(* * AcidExamples module *)
  
module AcidExamples = 
  struct
    open AcidTypes
    
    let nodes = [ Place;]
    let input_arcs = [
        InputArc ("A", Regular_iarc);
        InputArc ("A", Split_iarc);
        InputArc ("A", Filter_iarc "A");]
    let output_arcs = [
        OutputArc ("A", Regular_oarc);
        OutputArc ("A", Bind_oarc);
        OutputArc ("A", Move_oarc true);]
    let extensions = [
        Extension (Release_ext);
        Extension (Grab_ext (Graber.make [A;A;F;A;F;B;A]));
        Extension (Init_with_token_ext);
      ]

  end;;
        
