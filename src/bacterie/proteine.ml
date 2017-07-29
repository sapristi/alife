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
open Molecule.Molecule
open Molecule.AcidTypes
open Maps
open Petri_modules   
  


(* * the proteine module *)


module Proteine =
struct
  type t =
    {mol : molecule;
     transitions : Transition.t array;
     places : Place.t  array;
     mutable launchables : int list;

     (* À reconstruire en suivant la nouvelle forme des molécules

     message_receptors_book : (string, int) BatMultiPMap.t ;
     handles_book : (string, int) BatMultiPMap.t ;
     mol_catchers_book : (string, int) BatMultiPMap.t ;
      *)
    }
      
    
  let get_launchables (ts : Transition.t array) =
    let t_l = ref [] in 
    for i = 0 to Array.length ts -1 do
      if Transition.launchable ts.(i)
      then t_l := i :: !t_l
      else ()
    done; !t_l

(* should maybe be put in the Molecule module, but impossible for now
due to the type obfuscation *)
  let get_handles (mol : molecule) : (int * handle_id) list =
    let rec aux mol n =
      match mol with
      | Extension ext :: mol' ->
         begin
           match ext with
           | Handle_ext hid -> (n,hid) :: aux mol' (n+1)
           | _ -> aux  mol' (n+1)
         end
      | _ :: mol' -> aux mol' (n+1)
      | [] -> []
    in
    aux mol 0
    
  let make (mol : molecule) : t = 
  (* liste des signatures des transitions *)
    let transitions_signatures_list = build_transitions mol
  (* liste des signatures des places *)
    and places_signatures_list = build_nodes_list_with_exts mol
  in
(* on crée de nouvelles places à partir de  
   la liste de types données dans la molécule *)
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
  (* dictionnaire pour retrouver rapidement les places
     qui reçoivent des messages *)
    in
  (* À reconstruire avec la nouvelle forme des molécules
     
     fonction qui permet de créer des dictionnaires pour les 
     places qui reçoivent des messages, les places qui attrapent
     des molécules et les poignées 

    let rec create_books 
              (places : Place.t list)
              (n : int) :

              (((string, int) BatMultiPMap.t)
               * ((string, int) BatMultiPMap.t)
               * ((string, int) BatMultiPMap.t))
      =
      match places with
      | p :: places' ->
         let imb, mcb, hb = create_books places' (n+1) in 
         begin
           match p with
           | Receive_place s -> BatMultiPMap.add s n imb, mcb, hb
           | Catch_place s -> imb, BatMultiPMap.add s n mcb, hb
           | Handle_place s -> imb, mcb, BatMultiPMap.add s n hb
           | _ -> imb, mcb, hb
         end
      | [] -> 
         (
           BatMultiPMap.create compare (-), 
           BatMultiPMap.create compare (-), 
           BatMultiPMap.create compare (-)
         )
    in 
    let (message_receptors_book, mol_catchers_book, handles_book) = 
      create_books places_signatures_list 0
    in  *)
    {mol; transitions; places; launchables = (get_launchables transitions);
     (* message_receptors_book; handles_book; mol_catchers_book;*)
    }


      
  (* mettre à jour les transitions qui peuvent être lancées.
     Il faut prendre en compte la transition qui vient d'être lancée, 
     ainsi que les tokens qui ont pu arriver par message 

     (du coup, faire plus efficace devient un peu du bazar)
     on peut faire beaucoup plus efficace, mais pour l'instant 
     on fait au plus simple *)
  let update_launchables p =
    p.launchables <- get_launchables p.transitions



  let launch_transition (tId : int) p = 
    let initialTokens =
      List.fold_left 
        (fun l x ->
          let token = Place.pop_token p.places.(x) in
          token :: l)
        [] p.transitions.(tId).Transition.departure_places
    in 
    let finalTokens =
      Transition.transition_function initialTokens p.transitions.(tId)
    in
    BatList.map2
      (fun token place_id ->
        Place.add_token_from_transition token p.places.(place_id))
      finalTokens p.transitions.(tId).Transition.arrival_places
      
  let launch_random_transition p  =
    if not (p.launchables = [])
    then 
      let t = random_pick_from_list p.launchables in
      launch_transition t p
    else []

      
  (* relaie le message aux places concernées, créant ainsi
     des tokens quand c'est possible *)
    (*
  let send_message (m : string) (p : t) = 
    BatSet.PSet.iter 
      (fun x -> Place.add_token_from_message p.places.(x)) 
      (BatMultiPMap.find m p.message_receptors_book)

  let bind_mol (m : molecule)  (pat : string) (p : t) : bool = 
    let targets = BatMultiPMap.find pat p.mol_catchers_book in
    let bindSiteId = Misc_library.random_pick_from_PSet targets in
    Place.add_token_from_binding m p.places.(bindSiteId)
     *)

      (* il manque les livres, on verra plus tard, 
         c'est déjà pas mal *)
  let to_json (p : t) =
    `Assoc [
      "places",
      `List (Array.to_list (Array.map Place.to_json p.places));
      "transitions",
      `List (Array.to_list (Array.map Transition.to_json p.transitions));
      "molecule",
      molecule_to_yojson p.mol;
      "launchables",
      `List (List.map (fun x -> `Int x) p.launchables);]

  let to_json_update (p:t) =
    `Assoc [
      "places",
      `List (Array.to_list (Array.map Place.to_json p.places));
      "launchables",
      `List (List.map (fun x -> `Int x) p.launchables);]

      
end;;


(* *  examples de molecules et proteines test *)


let mol1 = [Node Regular_place];;
let prot1 = Proteine.make mol1;;

let mol2 = [Node Regular_place; Extension Init_with_token; TransitionInput ("a", Regular_ilink); Node Regular_place; TransitionOutput ("a", Regular_olink); Node Regular_place];;
let prot2 = Proteine.make mol2;;
