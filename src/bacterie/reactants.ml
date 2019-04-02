

open Reaction
open Local_libs
open Yaac_config
open Easy_logging_yojson
open Batteries
open Local_libs.Numeric.Num
module MolMap =
  struct
    include Map.Make (struct type t = Molecule.t
                             let compare = Pervasives.compare end)
                     (*   include Exceptionless *)
  end
  
(* ** module ARMap to interact with the active reactants *)
(*    + add, remove : *)
(*         takes a ref to an areactant and *)
(* 	adds it to (removes it from) the bactery *)
(*    + add_reacs_with_new_reactant : *)
(*         iterates through the present areactants to *)
(* 	add the possible reactions with the new reactant *)

module ARMap =
  struct

(* *** module Amolset *)
    module AmolSet =
      struct
        include Batteries.Set.Make (
                    struct
                      type t = Reactant.Amol.t
                      let compare =
                        fun (amd1 :t) (amd2:t) ->
                        Reactant.Amol.compare
                          amd1 amd2
                    end)
              
        let make mol =
          empty
          
        let logger = Logging.get_logger "Yaac.Bact.Internal.Amolset"
                       
                   

        let find_by_id pnet_id amolset  =
          let (dummy_pnet : Petri_net.t) ={
              mol = ""; transitions = [||];places = [||];
              uid = pnet_id; launchables_nb = zero;} in
          let dummy_amd = (Reactant.Amol.make_new dummy_pnet)
          in
          find dummy_amd amolset
          
          
        let add_reacs_with_new_reactant (new_reactant : Reactant.t) (amolset :t) reac_mgr : unit =
          if is_empty amolset
          then
            ()
          else
            let any_pnet = (any amolset).pnet in
            
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
    type t = AmolSet.t MolMap.t ref
            
           
    let logger = Logging.get_logger "Yaac.Bact.Internal.ARMap"
                   

    let add (areactant :Reactant.Amol.t )  (armap : t) : Reacs.effect list =
      logger#info "add %s" (Reactant.Amol.show areactant);

      armap :=
        MolMap.modify_opt
          areactant.mol
          (fun data ->
            match data with
            | Some amolset ->
               Some ( AmolSet.add areactant amolset )
            | None ->
               Some( AmolSet.singleton areactant )
          ) !armap;
      (* we should return the list of reactions to update *)
      [ Reacs.Update_reacs !(areactant.reacs)]

    let total_nb (armap :t) =
      MolMap.fold (fun _ amset t -> t + (num_of_int (AmolSet.cardinal amset))) !armap zero
      
    let remove (areactant : Reactant.Amol.t) (armap : t) : Reacs.effect list =
      armap :=
        MolMap.modify
          areactant.mol
          (fun  amolset ->  AmolSet.remove areactant amolset )
          !armap;
        
      [ Reacs.Remove_reacs !(areactant.reacs)]

      
    let get_pnet_ids mol (armap :t) =
      MolMap.find mol !armap
      |> AmolSet.enum
      |> Enum.map  (fun (amd : Reactant.Amol.t) ->
             amd.pnet.uid)
      |> List.of_enum

    let find mol pnet_id (armap : t) =
      try
        let amolset = MolMap.find mol !armap in
        
          AmolSet.find_by_id pnet_id amolset
      with
      | _   ->
         logger#error "cannot find %s:%d" mol pnet_id;
         failwith "ok"
      
    let add_reacs_with_new_reactant (new_reactant : Reactant.t)
                                    (armap :t)  reac_mgr: unit =
      
      logger#info "adding reactions with %s" (Reactant.show new_reactant);
      MolMap.iter 
        (fun _ areac -> 
          AmolSet.add_reacs_with_new_reactant
            new_reactant
            areac
            reac_mgr)
        !armap
      
  end

(* ** module IRMap to interact with inert reactants *)

module IRMap =
  struct
    type t = (Reactant.ImolSet.t) MolMap.t ref

    let logger = Logging.get_logger "Yaac.Bact.Internal.IRMap"
                   

           
    let add_to_qtt (ir : Reactant.ImolSet.t) deltaqtt (irmap : t)
        : Reacs.effect list =
      let imolset = MolMap.find ir.mol !irmap in
      Reactant.ImolSet.add_to_qtt deltaqtt imolset;
      [Reacs.Update_reacs !(ir.reacs)]
      
    let set_qtt qtt mol (irmap : t)  : Reacs.effect list=
      
      let imolset = MolMap.find mol !irmap in
      Reactant.ImolSet.set_qtt qtt imolset;
      [ Reacs.Update_reacs !(imolset.reacs)]

      
    let set_ambient ambient mol (irmap :t) =
      let imolset = MolMap.find mol !irmap in
       Reactant.ImolSet.set_ambient ambient imolset
      
      
    let remove_all mol (irmap : t) =
      let imolset = MolMap.find mol !irmap in
      let reacs = Reactant.ImolSet.reacs imolset in
      irmap := MolMap.remove mol !irmap;
      [ Reacs.Remove_reacs reacs]

      
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
           !irmap
        
      | ImolSet _ -> ()
      
        
  end
  
