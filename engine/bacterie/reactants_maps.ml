(**

modules defined in this file:
   - ARMap : structure holding active reactants (that is, molecules with PNet)
   - IRMap : structure holding inactive reactants
*)

open Reaction
open Local_libs
(* open Yaac_config *)
open Easy_logging_yojson
open Base_chemistry
(* open Local_libs.Numeric *)
module MolMap =
  struct
    include CCMap.Make (struct type t = Molecule.t
                               let compare = compare end)

    (*let show : Molecule.t t -> string =
      Format.sprintf pp t*)
                     (*   include Exceptionless *)

  end

(* ** module ARMap to interact with the active reactants *)
(*    + add, remove : *)
(*         takes a ref to an areactant and *)
(* 	adds it to (removes it from) the bactery *)
(*    + add_reacs_with_new_reactant : *)
(*         iterates through the present areactants to *)
(* 	add the possible reactions with the new reactant *)


(* apparently, AmolSet is a step toward splitting ARMap into
 * multiple sets, organised by molecule. For now, each AmolSet
 * holds at most one reactant *)



module ARMap =
  struct

    (** module Amolset: set of Amol
        All Amol are expected to come from the same molecule.
    *)
    module AmolSet =
      struct
        include CCSet.Make (
                    struct
                      type t = Reactant.Amol.t
                      let compare =
                        fun (amd1 :t) (amd2:t) ->
                        Reactant.Amol.compare
                          amd1 amd2
                    end)

        let to_yojson (amolset: t) : Yojson.Safe.t =
          (** Exported as a list of Amol*)
          `List (
            amolset |> to_list  |> List.map Reactant.Amol.to_yojson
          )
        let of_yojson (input: Yojson.Safe.t) : (t, string) result =
          match input with
          | `List items ->
            let res = ref empty in
            Base.With_return.with_return (fun r ->
                List.iter (fun item ->
                    match Reactant.Amol.of_yojson item with
                    | Ok amol -> res := add amol !res
                    | Error e -> r.return (Error e)
                  ) items;
                Ok (!res)
              )
          | _ -> Error "Cannot Amolset parse from json"

        let pp = pp ~pp_start:(Misc_library.printer "AmolSet:\n") Reactant.Amol.pp
        let show amolset =
          Format.asprintf "%a" pp amolset
        let make mol =
          empty

        let logger = Logging.get_logger "Yaac.Bact.Amolset"

        let find_by_id pnet_id amolset  =
          let (dummy_pnet : Petri_net.t) ={
              mol = ""; transitions = [||];places = [||];
              uid = pnet_id; launchables_nb = 0;} in
          let dummy_amd = (Reactant.Amol.make_new dummy_pnet)
          in
          find dummy_amd amolset

        let add_reacs_with_new_reactant (new_reactant : Reactant.t) (amolset :t) reac_mgr : unit =
          (** Compute reactions with an other reactant, and add them to the given reac_mgr.
              This function is here because we have access to pnet that are already calculated
              TODO: check if it could be moved somewhere else.
          *)
          if is_empty amolset
          then
            ()
          else
            let any_pnet = (choose amolset).pnet in

            match new_reactant with
            | Amol new_amol ->

              let is_graber = Petri_net.can_grab
                  (Reactant.mol new_reactant)
                  any_pnet
              and is_grabed = Petri_net.can_grab
                  any_pnet.mol
                  new_amol.pnet  in

              iter
                (fun current_amd ->
                   if is_graber
                   then
                     (
                       Reac_mgr.add_grab current_amd new_reactant reac_mgr;
                       logger#debug  "[%s] grabing %s" (Reactant.show (Amol current_amd)) (Reactant.show new_reactant) |> ignore;
                     );
                   if is_grabed
                   then
                     (
                       Reac_mgr.add_grab new_amol (Amol current_amd) reac_mgr;
                       logger#debug "[%s] grabed by %s"  (Reactant.show (Amol current_amd)) (Reactant.show new_reactant) |> ignore;
                     );
                 ) amolset;

            | ImolSet _ ->
               if Petri_net.can_grab (Reactant.mol new_reactant) any_pnet
               then
                 iter
                   (fun current_amol ->
                     logger#debug "[%s] grabing %s" (Reactant.show (Amol current_amol)) (Reactant.mol new_reactant);
                     Reac_mgr.add_grab current_amol new_reactant reac_mgr)
                   amolset

      end

    (** ARMap:
        Association map from molecule to Amolset
    *)
    type t = {
        mutable v:  AmolSet.t MolMap.t
      }
    let to_yojson armap : Yojson.Safe.t =
      `Assoc (
        MolMap.to_list armap |> List.map (fun (mol, amolset) -> (mol, AmolSet.to_yojson amolset))
      )

    let of_yojson (input: Yojson.Safe.t) : (t, string) result =
      match input with
      | `Assoc items ->
        let res = { v= MolMap.empty} in
        Base.With_return.with_return (fun r ->
            List.iter (fun (mol, item) ->
                match AmolSet.of_yojson item with
                | Ok amol -> res.v <- MolMap.add mol amol res.v
                | Error e -> r.return (Error e)
              ) items;
            Ok res
          )
      | _ -> Error "Cannot parse ARMap from json"

    let pp = MolMap.pp Molecule.pp AmolSet.pp
    let show armap =
          Format.asprintf "%a" pp armap
    let logger = Logging.get_logger "Yaac.Bact.ARMap"

    let make () = {v = MolMap.empty}

    (** Either add the reactant to an existing AmolSet, or create a new one
        Returns the list of reactions to update
    *)
    let add (areactant :Reactant.Amol.t )  (armap : t) : Reacs.effect list =
      logger#trace "Adding Reactant.Amol %s" (Reactant.Amol.show areactant);

      armap.v <-
        MolMap.update
          areactant.mol
          (fun data ->
            match data with
            | Some amolset ->
               Some ( AmolSet.add areactant amolset )
            | None ->
               Some( AmolSet.singleton areactant )
          ) armap.v;
      (* we should return the list of reactions to update *)
      [ Reacs.Update_reacs !(areactant.reacs)]

    let total_nb (armap :t) =
      let open Q in
      MolMap.fold (fun _ amset t -> t + (of_int (AmolSet.cardinal amset))) armap.v zero

    let remove (areactant : Reactant.Amol.t) (armap : t) : Reacs.effect list =
      logger#trace "Removing Reactant.Amol %s" (Reactant.Amol.show areactant);

      armap.v <-
        MolMap.update
          areactant.mol
          (fun  amolseto ->
            match amolseto with
            | None ->
               logger#error "Trying to remove nonexistent Amol %s from %s"
                 (Reactant.Amol.show areactant) (show armap.v);
               raise Not_found
            | Some amolset ->
               if Config.remove_empty_reactants
               then
                 let new_aset = AmolSet.remove areactant amolset in
                 if AmolSet.is_empty new_aset
                 then None
                 else Some new_aset
               else
                 Some (AmolSet.remove areactant amolset)
          ) armap.v;

      [ Reacs.Remove_reacs !(areactant.reacs)]


    let get_pnet_ids mol (armap :t) =
      MolMap.find mol armap.v
      |> AmolSet.to_list
      |> List.map  (fun (amd : Reactant.Amol.t) ->
             amd.pnet.uid)


    let find mol pnet_id (armap : t) =
      try
        let amolset = MolMap.find mol armap.v in

          AmolSet.find_by_id pnet_id amolset
      with
      | _   ->
         logger#error "Cannot find %s:%d in:\n%s" mol pnet_id (show armap.v);
         raise Not_found

    let add_reacs_with_new_reactant (new_reactant : Reactant.t)
                                    (armap :t)  reac_mgr: unit =

      logger#trace "adding reactions with %s" (Reactant.show new_reactant);
      MolMap.iter
        (fun _ areac ->
          AmolSet.add_reacs_with_new_reactant
            new_reactant
            areac
            reac_mgr)
        armap.v

  end

(* ** module IRMap to interact with inert reactants *)

module IRMap =
  struct
    type t = {mutable v : Reactant.ImolSet.t MolMap.t}

    let to_yojson irmap : Yojson.Safe.t =
      `Assoc (
      MolMap.to_list irmap |> List.map (fun (mol, imolset) -> (mol, Reactant.ImolSet.to_yojson imolset))
    )

    let of_yojson (input: Yojson.Safe.t) : (t, string) result =
      match input with
      | `Assoc items ->
        let res = { v= MolMap.empty} in
        Base.With_return.with_return (fun r ->
            List.iter (fun (mol, item) ->
                match Reactant.ImolSet.of_yojson item with
                | Ok amol -> res.v <- MolMap.add mol amol res.v
                | Error e -> r.return (Error e)
              ) items;
            Ok res
          )
      | _ -> Error "Cannot parse IRMap from json"


    let pp = MolMap.pp Molecule.pp Reactant.ImolSet.pp
    let show irmap =
          Format.asprintf "%a" pp irmap
    let logger = Logging.get_logger "Yaac.Bact.IRMap"


    (** External API : should not be called from other internal functions *)
    module Ext =
      struct
        let set_qtt qtt mol (irmap : t)  : Reacs.effect list =
          let imolset = MolMap.find mol irmap.v in
          Reactant.ImolSet.set_qtt qtt imolset;
          [ Reacs.Update_reacs !(imolset.reacs)]

        let set_ambient ambient mol (irmap :t) =
          let imolset = MolMap.find mol irmap.v in
          Reactant.ImolSet.set_ambient ambient imolset

        let remove_all mol (irmap : t) =
          let imolset = MolMap.find mol irmap.v in
          let reacs = Reactant.ImolSet.reacs imolset in
          irmap.v <- MolMap.remove mol irmap.v;
          [ Reacs.Remove_reacs reacs]
      end

    let make () = {v = MolMap.empty}

    let add (ireac : Reactant.ImolSet.t) irmap =
      irmap.v <- MolMap.add ireac.mol ireac irmap.v

    let add_to_qtt (ir : Reactant.ImolSet.t) deltaqtt (irmap : t)
        : Reacs.effect list =
      let imolset = MolMap.find ir.mol irmap.v in
      Reactant.ImolSet.add_to_qtt deltaqtt imolset;
      if Config.remove_empty_reactants && imolset.qtt = 0
      then
        Ext.remove_all imolset.mol irmap
      else
      [Reacs.Update_reacs !(ir.reacs)]


    let add_reacs_with_new_reactant (new_reactant : Reactant.t)
          (irmap :t) reac_mgr =
      match new_reactant with
      | Amol new_amol ->
         MolMap.iter
           (fun mol ireactant ->
             if Petri_net.can_grab mol new_amol.pnet
             then
               (
                 Reac_mgr.add_grab new_amol (ImolSet ireactant) reac_mgr;
                 logger#debug "[%s] grabed by %s" ireactant.mol (Reactant.show new_reactant)
               |> ignore;
               )
           )
           irmap.v

      | ImolSet _ -> ()


  end
