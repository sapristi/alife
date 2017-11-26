(* * this file *)
(*   We define here the working of a proteine, implemented using the acid  *)
(*   type defined in custom_types. *)
(*   modules in this file have custom json serialisers, that are used to  *)
(*   communicate data with a client *)

(* * preamble *)
(* commands used when compiling the file in a toplevel *)

(* #use "topfind";; *)
(* #require "batteries";; *)
(* #require "yojson" ;; *)
(* #require "ppx_deriving_yojson";; *)
(* #require "ppx_deriving.show";; *)

(* Used to add directories to load librairies (cmo). Can be avoided using -I "path" when launching toplevel. *)

(* #directory "/home/sapristi/Documents/projets/alife/_build/src/libs";; *)
(* #directory "/home/sapristi/Documents/projets/alife/_build/src/bacterie";; *)


(* #load "misc_library.cmo";; *)
(* #load "molecule.cmo";; *)
(* #load "custom_types.cmo";; *)


open Batteries
open Misc_library
open Maps
open Random

(* * the proteine module *)


type t =
  {
    mol : Molecule.t;
    transitions : Transition.t array;
    places : Place.t  array;
    mol_grabers_book : (Graber.t, int) BatMultiPMap.t;
  } 
  
let update_launchables (pnet :t) : unit =
  Array.iter (fun t -> Transition.update_launchable t) pnet.transitions
  
let make_from_prot (prot : Proteine.t)  (mol : Molecule.t) : t =
  try
    (* liste des signatures des transitions *)
    let transitions_signatures_list = Proteine.build_transitions prot
    (* liste des signatures des places *)
    and places_signatures_list = Proteine.build_nodes_list_with_exts prot
    in
    (* on crée de nouvelles places à partir de la liste de types données dans la molécule *)
    let places : Place.t array = 
      let psigs = ref places_signatures_list in
      Array.init
        (List.length !psigs)
        (fun index -> 
          let p = List.hd !psigs in
          psigs := List.tl !psigs;
          Place.make p index)
      
    in
    let (transitions : Transition.t array) = 
      let tsigs = ref transitions_signatures_list in
      Array.init
        (List.length !tsigs)
        (fun index -> 
          let (id, ila, ola) = List.hd !tsigs in
          tsigs := List.tl !tsigs;
          Transition.make id places ila ola index)
      
    and mol_grabers_book = Proteine.build_grabers_book prot
                         
    in
    {mol; transitions; places;
     mol_grabers_book}
  with
  | _ ->
     print_endline "cannot build pnet";
     {mol=""; transitions=[||]; places=[||];mol_grabers_book= BatMultiPMap.empty}
     
let make_from_mol (mol : Molecule.t) : t =
  let prot = Molecule.to_proteine mol in
  make_from_prot prot mol
  
(* mettre à jour les transitions qui peuvent être lancées. *)
(* Il faut prendre en compte la transition qui vient d'être lancée,  *)
(* ainsi que les tokens qui ont pu arriver par message  *)

(* (du coup, faire plus efficace devient un peu du bazar) *)
(* on peut faire beaucoup plus efficace, mais pour l'instant  *)
(* on fait au plus simple *)


let launch_transition_by_id (tId : int) p =
  Transition.apply_transition p.transitions.(tId)
  
let launch_random_transition (p : t)
    : Place.transition_effect list =
  let launchables = Array.filter (fun (t:Transition.t) -> t.launchable) p.transitions in
  if Array.length launchables > 0
  then 
    let t = random_pick_from_array launchables in
    Transition.apply_transition t
  else []
  
(* returns a list of all the possible grabs of a molecule *)
let get_possible_mol_grabs (mol : Molecule.t) (pnet : t) : (int*int) list =
  Array.fold_lefti
    (fun g_list i place ->
      (Place.get_possible_mol_grabs mol place i)@g_list)
    [] pnet.places

let grab (mol : Molecule.t) (pos : int) (pid : int) (pnet : t)
    : bool = 
  let token = Token.make mol pos in
  Place.add_token_from_grab token (pnet.places.(pid))
  
  
let to_json (p : t) =
  `Assoc [
     "places",
     `List (Array.to_list (Array.map Place.to_yojson p.places));
     "transitions",
     `List (Array.to_list (Array.map Transition.to_yojson p.transitions));
     "molecule",
     Molecule.to_yojson p.mol]
  



   (* reliquat de la fonction qui associe catchers et 
       handle; pourra servir plus tard *)
   (*
    let bind_places_ids =
      BatMultiPMap.find bind_pattern pnet.handles_book 
    in
    let free_places_ids = 
      BatSet.PSet.filter
        (fun id -> Place.is_empty pnet.places.(id))
        bind_places_ids
    in
    if BatSet.PSet.is_empty free_places_ids
    then false
    else
      let bind_place_id =
        Misc_library.random_pick_from_PSet free_places_ids
      in
      Place.add_token_from_binding mol pnet.places.(bind_place_id)
    *)
