

open Local_libs
open Reaction
open Reactants_maps
(* open Yaac_config *)
open Local_libs
open Local_libs.Numeric
open Local_libs.Misc_library
open Base_chemistry


(* * Container module *)


(* Une bacterie est un conteneur à molecules. Elle s'occupe de fournir  *)
(* l'interprétation d'une molécule en tant que protéine (i.e. pnet),  *)
(* puis d'organiser la simulation des pnet et de leurs interactions. *)

(* Pour organiser la simulation, il faut : *)
(*  - organiser le lancement des transitions *)
(*  - gérer les réactions *)

(* Pour rentrer dans le cadre Stochastic Simulations, *)
(* il faut associer à chaque réaction une probabilité. *)
(* Le calcul de la réaction suivante nécéssite de calculer la *)
(* proba de chacune des réactions, ce qui se fait en N² où N *)
(* est le NOMBRE total de molécules (c'est beaucoup trop). *)




let logger = Jlog.make_logger "Yaac.Bact.Bacterie"


type t = {
  ireactants : IRMap.t;
  areactants : ARMap.t;
  reac_mgr : Reac_mgr.t;
  env : Environment.t ref;
  randstate : Random_s.t ref;
  mutable id_counter: int;
}
[@@deriving eq]

let copy bact : t =
  let env = ref !(bact.env) in
  let reac_mgr = {bact.reac_mgr with env = env} in
  {
    ireactants = IRMap.copy bact.ireactants;
    areactants = ARMap.copy bact.areactants;
    reac_mgr;
    env;
    randstate = ref !(bact.randstate);
    id_counter = bact.id_counter;
  }

let default_randstate = {
  Random_s.seed = 8085733080487790103L;
  gamma = -7046029254386353131L
}

let make_empty ?(env=Environment.null_env) () =
  let renv = ref env in
  {
    ireactants= IRMap.make ();
    areactants= ARMap.make ();
    reac_mgr = Reac_mgr.make_new renv;
    env = renv;
    randstate = ref default_randstate;
    id_counter = 0;
  }

let get_pnet_uid bact =
  let res = bact.id_counter in
  bact.id_counter <- bact.id_counter + 1;
  res



let add_active_molecule (mol: Molecule.t) (pnet: Petri_net.t) (bact: t): Reacs.effect list =
  (** Adds the given pnet to the bactery *)
  logger.debug ~tags:["mol", `String mol] "adding active molecule";

  let ar = Reactant.Amol.make_new pnet in
  (* reactions : grabs with other amols*)
  ARMap.add_reacs_with_new_reactant (Amol ar) bact.areactants bact.reac_mgr;

  (* reactions : grabs with inert mols *)
  IRMap.add_reacs_with_new_reactant (Amol ar) bact.ireactants bact.reac_mgr;

  (* reaction : transition  *)
  Reac_mgr.add_transition ar bact.reac_mgr;

  (* reaction : break *)
  Reac_mgr.add_break (Amol ar) bact.reac_mgr;

  (* reaction : collisions *)
  Reac_mgr.add_collider (Amol ar) bact.reac_mgr;

  (* we add the reactant after adding reactions
     because it must not react with itself *)
  ARMap.add ar bact.areactants


let add_inert_molecule ?(qtt = 1) ?(ambient = false) (mol: Molecule.t) (bact: t): Reacs.effect list =
  logger.debug ~tags:["mol", `String mol] "adding inert molecule";
  match MolMap.get mol bact.ireactants.v with
  | None ->
    let new_ireac = Reactant.ImolSet.make_new mol ~qtt ~ambient in
    (* reactions : grabs *)
    ARMap.add_reacs_with_new_reactant
      (ImolSet new_ireac) bact.areactants bact.reac_mgr;

    (* reactions : break *)
    Reac_mgr.add_break (ImolSet new_ireac) bact.reac_mgr;

    (* reactions : collision *)
    Reac_mgr.add_collider (ImolSet new_ireac) bact.reac_mgr;

    (* add molecule *)
    IRMap.add new_ireac bact.ireactants;

    [ Reacs.Update_reacs !(new_ireac.reacs) ]

  | Some ireac ->
    IRMap.add_to_qtt ireac qtt bact.ireactants

(** Adds a single molecule to a container (bactery).
    We have to take care :
    - if the molecule is active, we must create a new active_reactant,
       add all possible reactions with this reactant, then add it to
       the bactery (whether or not other molecules of the same species
       were already present)
    - if the molecule is inactive, the situation depends on whether
       the species was present or not :
       + if it was already present, we modify it's quatity and update
         related reaction rates
       + if it was not, we add the molecules and the possible reactions

    Note: could be made more efficient when adding multiple molecules -
    let's keep it simple for now
*)
let add_molecule (mol : Molecule.t) (bact : t) : Reacs.effect list =

  if Config.check_mol && (not (Molecule.check mol))
  then
    (
    logger.warning ~tags:["mol", `String mol] "Ignoring add of bad molecule";
    []
  )
  else
    let uid = get_pnet_uid bact in
    let new_opnet = Petri_net.make_from_mol uid mol in
      match new_opnet with
      | Some pnet -> add_active_molecule mol pnet bact
      | None -> add_inert_molecule mol bact



(** totally removes a molecule from a bactery *)
let remove_one_reactant (reactant : Reactant.t) (bact : t) : Reacs.effect list =
  match reactant with
  | ImolSet ir ->
    IRMap.add_to_qtt ir (-1) bact.ireactants
  | Amol amol ->
    ARMap.remove amol bact.areactants
  | Dummy -> failwith "Dummy"


(** Execute actions after a transition from a pnet has occured (or a new element has been added)
    Some actions may need to be performed by the bactery

    TODO later : ???
    il faudrait peut-être mettre dans une file les molécules à ajouter *)
let rec execute_actions (bact :t) (actions : Reacs.effect list) : unit =
  List.iter
    (fun (effect : Reacs.effect) ->
       logger.debug ~tags:["effect", Reacs.effect_to_yojson effect] "Executing effect";
       match effect with
       | T_effects tel ->
         List.iter
           (fun teffect ->
              match teffect with
              | Place.Release_effect mol  ->
                if mol != ""
                then
                  add_molecule mol bact
                  |> execute_actions bact
              | Place.Message_effect m  ->
                (* bact.message_queue <- m :: bact.message_queue; *)
                ()
           ) tel
       | Update_launchables amol ->
         Petri_net.update_launchables amol.pnet
       | Update_reacs reacset ->
         Reac_mgr.update_rates reacset bact.reac_mgr
       | Remove_reacs reacset ->
         Reac_mgr.remove_reactions reacset bact.reac_mgr
       | Remove_one reactant ->
         remove_one_reactant reactant bact
         |> execute_actions bact
       | Release_mol mol ->
         add_molecule mol bact
         |> execute_actions bact
       | Release_tokens tlist ->
         List.iter (fun (n,mol) ->
             add_molecule mol bact
             |> execute_actions bact) tlist

     (* Possible effects :
        - forced grab : a molecule is fitted into a pnet
          even though a grab could not possibly occur
          (this could be parameterized with
          some kind of bind probability)
        - mix : the molecules are mixed together,
          or one is put into the other one
        - both break
     *)
    )
    actions


let stats_logger = Jlog.make_logger "Stats"

let stats bact =
  [
    "ireactants", IRMap.stats bact.ireactants;
    "areactants", ARMap.stats bact.areactants;
    "reactions",  (Reac_mgr.stats bact.reac_mgr);
  ]

let next_reaction (bact : t)  =
  let begin_time = Sys.time () in
  let r = Reac_mgr.pick_next_reaction !(bact.randstate) bact.reac_mgr in
  match r with
  | None -> ()
  | Some r ->
    let picked_time = Sys.time () in
    try
      let actions = Reaction.treat_reaction !(bact.randstate) r in
      let treated_time = Sys.time () in
      execute_actions bact actions;
      let end_time = Sys.time () in

      stats_logger.info ~tags:[
        "picking_duration", `Float (picked_time -. begin_time);
        "treating_duration", `Float (treated_time -. picked_time);
        "post-actions_duration", `Float (end_time -. treated_time);
      ] "Stats";
    with
    | _ as e ->
      logger.error ~tags:[
        "backtrace", `String (Printexc.get_backtrace ());
        "exception", `String (Printexc.to_string e);
        "reaction", Reaction.to_yojson r
      ] "An error happened while treating reaction";
      raise e


(** Allows to encode the full state of a bactery in json
    Reactions are not exported, since we expect to reconstruct them from the present molecules.
*)
module FullSig = struct
  type bacterie = t
  type t = {
    ireactants: IRMap.Serialized.t;
    areactants: ARMap.Serialized.t;
    env: Environment.t;
    randstate: Random_s.t;
    id_counter: int;
    reac_counter: int;
  }
  [@@deriving yojson, show]


  let of_bact  (bact: bacterie) =
    {
      ireactants = IRMap.Serialized.ser bact.ireactants;
      areactants = ARMap.Serialized.ser bact.areactants;
      env = !(bact.env);
      randstate = !(bact.randstate);
      id_counter = bact.id_counter;
      reac_counter = bact.reac_mgr.reac_counter;
    }

  let bact_to_yojson (bact: bacterie) =
    bact |> of_bact |> to_yojson

  let bact_of_yojson input =
    let serialized_res = of_yojson input in
    match serialized_res with
    | Error s -> Error s
    | Ok serialized ->
      let renv = ref serialized.env in
      let bact = {
        ireactants = IRMap.make ();
        areactants = ARMap.make ();
        reac_mgr = Reac_mgr.make_new ~reac_counter:serialized.reac_counter renv;
        env = renv;
        randstate = ref serialized.randstate;
        id_counter = serialized.id_counter;
      } in
      List.iter (
        fun ({mol; qtt; ambient}: IRMap.Serialized.item) ->
          add_inert_molecule  ~qtt ~ambient mol bact |> execute_actions bact
      ) serialized.ireactants;
      List.iter (
        fun ((mol, pnets): ARMap.Serialized.item) ->
          List.iter (
            fun pnet -> add_active_molecule mol pnet bact |> execute_actions bact
          ) pnets
      ) serialized.areactants;
      Ok bact

end

(** Partial representation, used for initial states, tests, etc *)
module CompactSig = struct
  type mol_sig = {
    mol: Molecule.t;
    qtt: int; [@default 1]
    ambient: bool [@default false]
  }
  [@@deriving yojson {strict=false}, ord, show]

  type bacterie = t
  type t = {
    mols : mol_sig list;
    env: Environment.t;
  }
  [@@deriving yojson, show]


  (** Returns a canonical signature - where the mols are in a deterministic order *)
  let canonical (cs : t) : t =
    {
      mols = List.sort compare (List.filter (fun (m : mol_sig) -> m.qtt > 0) cs.mols);
      env = cs.env;
    }

  let to_bact
      (bact_sig : t)
    : bacterie  =
    let bact = make_empty ~env:bact_sig.env () in
    List.iter
      (fun {mol; qtt; ambient} ->
         let test_opnet = Petri_net.make_from_mol 0 mol in
         match test_opnet with
         | Some pnet ->
           for i = 1 to qtt do
             add_active_molecule mol {pnet with uid = get_pnet_uid bact} bact
             |> execute_actions bact
           done
         | None -> add_inert_molecule ~qtt ~ambient mol bact
                   |> execute_actions bact;
      ) bact_sig.mols;
    bact


  let of_bact (bact : bacterie) : t =
    let imol_list = MolMap.to_list bact.ireactants.v in
    let trimmed_imol_list =
      List.map (fun (a,(imd: Reactant.ImolSet.t )) ->
          ({mol = imd.mol; qtt= imd.qtt;
            ambient = imd.ambient}))
        imol_list
    in
    let amol_list = MolMap.to_list bact.areactants.v in
    let trimmed_amol_list =
      List.map (fun (a, amolset) ->
          {mol = a; qtt = ARMap.AmolSet.cardinal amolset; ambient=false})
        amol_list

    in
    {
      mols = trimmed_imol_list @ trimmed_amol_list;
      env = !(bact.env);
    } |> canonical


end

let of_sig = CompactSig.to_bact
let to_sig = CompactSig.of_bact

let to_sig_yojson bact =
  CompactSig.to_yojson (to_sig bact)

let pp fmt bact =
  CompactSig.pp fmt (CompactSig.of_bact bact)

let pp_full fmt bact =
  FullSig.pp fmt (FullSig.of_bact bact)
