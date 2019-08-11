(**

modules defined in this file:
   - ARMap : structure holding active reactants (that is, molecules with PNet)
   - IRMap : structure holding inactive reactants   
*)

open Reaction
open Local_libs
open Yaac_config
open Easy_logging_yojson
(*open Batteries*)
open Local_libs.Numeric
module MolMap =
  struct
    include CCMap.Make (struct type t = Molecule.t
                               let compare = Pervasives.compare end)

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

(* *** module Amolset *)
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

        let pp = pp ~start:"AmolSet:\n " Reactant.Amol.pp
        let show amolset =
          Format.asprintf "%a" pp amolset
        let make mol =
          empty
          
        let logger = Logging.get_logger "Yaac.Bact.Internal.Amolset"
                       
                   

        let find_by_id pnet_id amolset  =
          let (dummy_pnet : Petri_net.t) ={
              mol = ""; transitions = [||];places = [||];
              uid = pnet_id; launchables_nb = Q.zero;} in
          let dummy_amd = (Reactant.Amol.make_new dummy_pnet)
          in
          find dummy_amd amolset
          
          
        let add_reacs_with_new_reactant (new_reactant : Reactant.t) (amolset :t) reac_mgr : unit =
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
                       Reac_mgr.add_grab new_amol (Amol current_amd) reac_mgr;
                       logger#debug  "[%s] grabing %s" (Reactant.show (Amol current_amd)) (Reactant.show new_reactant);
                     );
                   if is_grabed
                   then
                     (
                       Reac_mgr.add_grab current_amd new_reactant reac_mgr;
                       logger#debug "[%s] grabed by %s"  (Reactant.show (Amol current_amd)) (Reactant.show new_reactant);
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

(* *** ARMap defs *)      
    type t = {
        mutable v:  AmolSet.t MolMap.t
      }
           
    let pp = MolMap.pp Molecule.pp AmolSet.pp 
    let show armap =
          Format.asprintf "%a" pp armap
    let logger = Logging.get_logger "Yaac.Bact.Internal.ARMap"

    let make () = {v = MolMap.empty}

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
         logger#error "Cannot find %s:%d in %s" mol pnet_id (show armap.v);
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

    let pp = MolMap.pp Molecule.pp Reactant.ImolSet.pp 
    let show irmap =
          Format.asprintf "%a" pp irmap
    let logger = Logging.get_logger "Yaac.Bact.Internal.IRMap"


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
                 logger#debug "[%s] grabed by %s" ireactant.mol (Reactant.show new_reactant);
               )
           )
           irmap.v
        
      | ImolSet _ -> ()
      
        
  end
  
