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



open Local_libs
open Yaac_config
open Easy_logging_yojson
open Numeric

(* * the proteine module *)
let logger = Logging.get_logger "Yaac.Base_chem.Pnet"

include Chemistry_types.Types.Petri_net

let update_launchables (pnet :t) : unit =
  pnet.launchables_nb <- 0;
  Array.iter (fun t ->

      Transition.update_launchable t pnet.places;
      if t.launchable
      then pnet.launchables_nb <- pnet.launchables_nb + 1;

    ) pnet.transitions

let make_from_prot (prot : Proteine.t)  (mol : Molecule.t) : t option =

  lazy (Printf.sprintf "Building pnet from mol %s" mol)  |> logger#ldebug;
  lazy (Printf.sprintf "Proteine: %s" (Proteine.show prot)) |> logger#ldebug;
  try
    (* liste des signatures des transitions *)
    let transitions_signatures_list = Proteine.build_transitions prot
    (* liste des signatures des places *)
    and places_signatures_list = Proteine.build_nodes_list_with_exts prot
    in
    lazy (Misc_library.show_list_prefix "Made transitions signature"
            Proteine.show_transition_structure transitions_signatures_list)
    |> logger#ldebug;
    lazy (Misc_library.show_list_prefix "Made places signature"
            Proteine.show_place_extensions places_signatures_list)
    |> logger#ldebug;

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

    in
    let uid = Misc_library.idProvider#get_id ()

    in
    let launchables_nb =

      Array.fold_left
        (fun res t -> if t.Transition.launchable then Q.(res + one) else res)
        Q.zero transitions
    in
    lazy (Misc_library.show_array_prefix "Made places"
            Place.show places)
    |> logger#ldebug;

    (* simple filter to deactivate pnets without places or transitions *)
    let filter =
      if Config.build_inactive_pnets
      then
        fun p_l t_l -> p_l > 0
      else
        fun p_l t_l -> p_l > 0 && t_l > 0
    in
    if filter (Array.length places) (Array.length transitions)
    then
      Some {mol; transitions; places; uid; launchables_nb= Q.to_int launchables_nb;}
    else
      None
  with
  | _ as e->
     logger#warning "Error during pnet creation :\n%s\n%s"
       (Printexc.get_backtrace ())
       (Printexc.to_string e);

     None

let make_from_mol (mol : Molecule.t) : t option =
  let prot = Molecule.to_proteine mol in
  make_from_prot prot mol

(* mettre à jour les transitions qui peuvent être lancées. *)
(* Il faut prendre en compte la transition qui vient d'être lancée,  *)
(* ainsi que les tokens qui ont pu arriver par message  *)

(* (du coup, faire plus efficace devient un peu du bazar) *)
(* on peut faire beaucoup plus efficace, mais pour l'instant  *)
(* on fait au plus simple *)


let launch_transition_by_id (tId : int) p =
  Transition.apply_transition p.transitions.(tId) p.places

let launch_random_transition randstate (p : t)
    : Place.transition_effect list =
  let launchables = CCArray.filter (fun (t:Transition.t) -> t.launchable) p.transitions in
  if Array.length launchables > 0
  then
    let t = Random_s.pick_from_array randstate launchables in
    Transition.apply_transition t p.places
  else []

(* returns a list of all the possible grabs of a molecule *)
let get_possible_mol_grabs (mol : Molecule.t) (pnet : t) : (int*int) list =
  Array.fold_left
    (fun g_list place ->
      match Place.get_possible_mol_grabs mol place with
      | None -> g_list
      | Some (n, pid) -> (n, pid)::g_list)
    [] pnet.places

let grab (mol : Molecule.t) (pos : int) (pid : int) (pnet : t)
    : bool =
  let token = Token.make mol pos in
  Place.add_token_from_grab token (pnet.places.(pid))

(* *** functions to build the reactives *)
(* can be optimized, but this will do for now *)

let can_grab (mol : Molecule.t) (pnet : t) : bool =
  Array.fold_left
    (fun res place ->
      match place.Place.graber with
      | None -> res
      | Some g ->
         match Graber.get_match_pos g mol with
         | None -> res
         | Some _ -> true
    ) false pnet.places

let ocan_grab (mol : Molecule.t) (opnet : t option) : bool =
  match opnet with
  | None -> false
  | Some pnet ->
     Array.fold_left
       (fun res place ->
         match place.Place.graber with
         | None -> res
         | Some g ->
            match Graber.get_match_pos g mol with
            | None -> res
            | Some _ -> true
       ) false pnet.places

let grab_factor (mol : Molecule.t) (pnet : t) : Q.t =
  Array.fold_left
    (fun res place ->
      if Place.is_empty place
      then
        match place.Place.graber with
        | None -> res
        | Some g ->
           match Graber.get_match_pos g mol with
           | None -> res
           | Some _ -> Q.(res + one)
      else
        res
    ) Q.zero pnet.places


let can_react (mol1 : Molecule.t) (opnet1 : t option)
              (mol2 : Molecule.t) (opnet2 : t option) =
  match opnet1, opnet2 with
  | None, None -> false
  | Some pnet1, None -> can_grab mol2 pnet1
  | None, Some pnet2 -> can_grab mol1 pnet2
  | Some pnet1, Some pnet2 ->
       can_grab mol1 pnet2 ||
         can_grab mol2 pnet1


let get_tokens (pnet :t)  : Token.t list =
  Array.fold_left
    (fun res p ->
      match p.Place.token with
      | None -> res
      | Some t -> t::res)
    []
    pnet.places
