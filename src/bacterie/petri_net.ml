(* * this file *)
(* We define here the working of a proteine, implemented using the acid type defined in custom_types. *)
(* modules in this file have custom json serialisers, that are used to communicate data with a client *)

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
open Molecule
open Proteine
open Maps
open Place
open Transition
  
open Acid_types


(* * the proteine module *)


module PetriNet =
struct
  type t =
    {prot : Proteine.t;
     transitions : Transition.t array;
     places : Place.t  array;
     mutable launchables : int list;
     handles_book : (string, int) BatMultiPMap.t;
     mol_catchers_book : (string, int) BatMultiPMap.t ;
    }
      
    
  let get_launchables (ts : Transition.t array) =
    let t_l = ref [] in 
    for i = 0 to Array.length ts -1 do
      if Transition.launchable ts.(i)
      then t_l := i :: !t_l
      else ()
    done; !t_l
    
  let make_from_prot (prot : Proteine.t) : t =
  (* liste des signatures des transitions *)
    let transitions_signatures_list = Proteine.build_transitions prot
  (* liste des signatures des places *)
    and places_signatures_list = Proteine.build_nodes_list_with_exts prot
  in
  (* on crée de nouvelles places à partir de la liste de types données dans la molécule *)
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
  in
  let handles_book = Proteine.build_handles_book prot
  and mol_catchers_book = Proteine.build_catchers_book prot
                        

  in
  {prot; transitions; places;
   launchables = (get_launchables transitions);
   handles_book; mol_catchers_book;
   (* message_receptors_book; handles_book; *)
  }

  let make_from_mol (mol : Molecule.t) : t =
    let prot = Proteine.from_mol mol in
    make_from_prot prot
    
(* mettre à jour les transitions qui peuvent être lancées. *)
(* Il faut prendre en compte la transition qui vient d'être lancée,  *)
(* ainsi que les tokens qui ont pu arriver par message  *)

(* (du coup, faire plus efficace devient un peu du bazar) *)
(* on peut faire beaucoup plus efficace, mais pour l'instant  *)
(* on fait au plus simple *)

let update_launchables p =
  p.launchables <- get_launchables p.transitions


let launch_transition (tId : int) p = 
  Transition.apply_transition p.transitions.(tId)
    
let launch_random_transition p  =
  if not (p.launchables = [])
  then 
    let t = random_pick_from_list p.launchables in
    launch_transition t p
  else []

(* binds to a random free place if possible. *)
(* Returns true if bound happened, false otherwise *)
  let bind_mol (mol : Molecule.t)
               (bind_pattern : AcidTypes.bind_pattern)
               (pnet : t)
      : bool =
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
      
  let to_json (p : t) =
    `Assoc [
      "places",
      `List (Array.to_list (Array.map Place.to_json p.places));
      "transitions",
      `List (Array.to_list (Array.map Transition.to_json p.transitions));
      "molecule",
      Proteine.to_yojson p.prot;
      "launchables",
      `List (List.map (fun x -> `Int x) p.launchables);]

  let to_json_update (p:t) =
    `Assoc [
      "places",
      `List (Array.to_list (Array.map Place.to_json p.places));
      "launchables",
      `List (List.map (fun x -> `Int x) p.launchables);]      
end;;

