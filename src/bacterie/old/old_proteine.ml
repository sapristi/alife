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
open Acid_types
open Molecule
open Atome
open Graber

(* * Proteine module *)
module Proteine = 
  struct 
    
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
  | Node
  | InputArc of string * AcidTypes.input_arc_type
  | OutputArc of string * AcidTypes.output_arc_type
  | Extension of AcidTypes.extension_type
                   [@@deriving show, yojson]
                 

(* * A proteine *)                   
    type t = acid list
                  [@@deriving show, yojson]
                
(* *** position type definition *)
(*     Correspond à un pointeur vers un des acide de la molécule *)
                
type position = int
                  [@@deriving show]

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
                                             [@@deriving show]

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
    | Node :: prot' -> aux prot' (nodeN + 1) transL
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
        ((AcidTypes.extension_type list)) list =
    
    let rec aux prot res = 
      match prot with
      | Node :: prot' -> aux prot' (([]) :: res)
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

let build_handles_book (prot : t) : (string, int) BatMultiPMap.t =
  let rec aux prot n map =
    match prot with
    | Extension ext :: prot' ->
       begin
         match ext with
         | AcidTypes.Handle_ext hid ->
            aux prot' (n+1) (BatMultiPMap.add hid n map)
         | _ -> aux  prot' (n+1) map
       end
    | _ :: prot' -> aux prot' (n+1) map
    | [] -> map
  in
  aux prot 0 BatMultiPMap.empty
  
let build_catchers_book (prot : t) : (string, int) BatMultiPMap.t =
  let rec aux  prot n map =
    match prot with
    | Node _ :: prot' -> aux prot' (n+1) map
    | Extension ext :: prot' ->
       if n >= 0
       then
         begin
           match ext with
           | AcidTypes.Handle_ext hid ->
              aux prot' n (BatMultiPMap.add hid n map)
           | _ -> aux  prot' n map
         end
       else
         aux prot' n map
    | _ :: prot' -> aux prot' n map
    | [] -> map
  in
  aux prot (-1) BatMultiPMap.empty

let build_grabers_book (prot : t) : (Graber.t, int) BatMultiPMap.t =
  let rec aux  prot n map =
    match prot with
    | Node _ :: prot' -> aux prot' (n+1) map
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

  let rec from_mol (mol : Molecule.t) : t =
    match mol with
      
    | A::A::A::mol' -> (Node) :: from_mol mol'
                     
    | B::A::A::mol' ->
       let s,mol'' = Molecule.extract_message_from_mol mol' in
       (InputArc (s,Regular_iarc)) :: (from_mol mol'')
       
    | B::B::A::mol' ->
       let s,mol'' = Molecule.extract_message_from_mol mol' in
       (InputArc (s,Split_iarc)) :: (from_mol mol'')
       
    | B::C::a::mol' ->
       let s,mol'' = Molecule.extract_message_from_mol mol' in
       (InputArc (s,Filter_iarc (Atome.to_string a))) :: from_mol mol''
       
    | C::A::A::mol'->
       let s,mol'' = Molecule.extract_message_from_mol mol' in
       (OutputArc (s,Regular_oarc)) :: from_mol mol''
       
    | C::B::A::mol'->
       let s,mol'' = Molecule.extract_message_from_mol mol' in
       (OutputArc (s,Bind_oarc)) :: from_mol mol''
       
    | C::C::A::mol'->
       let s,mol'' = Molecule.extract_message_from_mol mol' in
       (OutputArc (s,Release_oarc)) :: from_mol mol''
       
    | D::A::A::mol'->
       let s,mol'' = Molecule.extract_message_from_mol mol' in
       (Extension (Handle_ext s)) :: from_mol mol''
       
    | D::B::A::mol'->
       let s,mol'' = Molecule.extract_message_from_mol mol' in
       (Extension (Catch_ext s)) :: from_mol mol''
       
    | D::D::A::mol'->
       (Extension Release_ext) :: from_mol mol'
      
    | D::B::B::mol'->
       (Extension (Displace_mol_ext true)) :: from_mol mol'
      
    | D::B::C::mol'->
       (Extension (Displace_mol_ext false)) :: from_mol mol'
      
    | D::C::B::mol'->
       (Extension Init_with_token_ext) :: from_mol mol'
      
    | D::D::B::mol' ->
       let s,mol'' = Molecule.extract_message_from_mol mol' in
       (Extension (Information_ext s)) :: from_mol mol''
       
    | D::D::C::mol' ->
       let s,mol'' = Molecule.extract_message_from_mol mol' in
       let g = Graber.build_from_string s in
       (Extension (Grab_ext g)) :: from_mol mol''
       
    | a :: mol' -> from_mol mol'
    | [] -> []

(* *** to_molecule *)
(* inverse of the previous function *)          

  let rec to_molecule (prot : t) : Molecule.t =
    match prot with
    | Node :: prot' ->
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
    | OutputArc (s,Release_oarc) :: prot' ->
       Atome.C::C::A::(Molecule.string_to_message_mol s)@(to_molecule prot')
    | Extension (Handle_ext s) :: prot' ->
       Atome.D::A::A::(Molecule.string_to_message_mol s)@(to_molecule prot')
    | Extension (Catch_ext s) :: prot' ->
       Atome.D::B::A::(Molecule.string_to_message_mol s)@(to_molecule prot')
    | Extension Release_ext :: prot' ->
       D::D::A::(to_molecule prot')
    | Extension (Displace_mol_ext true) :: prot' ->
       D::B::B::(to_molecule prot')
    | Extension (Displace_mol_ext false) :: prot' ->
       D::B::C::(to_molecule prot')
    | Extension Init_with_token_ext :: prot' ->
       D::C::B::(to_molecule prot')
    | Extension (Information_ext s) :: prot' ->
       Atome.D::D::B::(Molecule.string_to_message_mol s)@(to_molecule prot')
    | Extension (Grab_ext g) :: prot' ->
      D::D::C::((g.pattern_as_mol)@[Atome.F;F;F]@(to_molecule prot'))
      
    | [] -> []
          

end;;

(* * AcidExamples module *)
  
module AcidExamples = 
  struct
    
    let nodes = [ Proteine.Node;]
    let input_arcs = [
        Proteine.InputArc ("A", AcidTypes.Regular_iarc);
        Proteine.InputArc ("A", AcidTypes.Split_iarc);
        Proteine.InputArc ("A", AcidTypes.Filter_iarc "A");]
    let output_arcs = [
        Proteine.OutputArc ("A", AcidTypes.Regular_oarc);
        Proteine.OutputArc ("A", AcidTypes.Bind_oarc);
        Proteine.OutputArc ("A", AcidTypes.Release_oarc);]
    let extensions = [
        Proteine.Extension (AcidTypes.Release_ext);
        Proteine.Extension (AcidTypes.Displace_mol_ext true);
        Proteine.Extension (AcidTypes.Init_with_token_ext);
      ]

  end;;
        