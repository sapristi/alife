
open Batteries
open Reaction


module MolMap =
  struct
    include Map.Make (struct type t = Molecule.t
                             let compare = Pervasives.compare end)
                     (*   include Exceptionless *)
  end

  
(* ** module to interact with the active reactants *)
(*    + add, remove : *)
(*         takes a ref to an areactant and *)
(* 	adds it to (removes it from) the bactery *)
(*    + add_reacs_with_new_reactant : *)
(*         iterates through the present areactants to *)
(* 	add the possible reactions with the new reactant *)

module ARMap =
  struct
    
    module AmolSet =
      struct
        include Set.Make (
                 struct
                   type t = Reactant.Amol.t ref
                   let compare =
                     fun (amd1 :t) (amd2:t) ->
                     Reactant.Amol.compare
                       !amd1 !amd2
                 end)
           

        let find_by_id pnet_id amolset  =
          let (dummy_pnet : Petri_net.t) ={
              mol = ""; transitions = [||];places = [||];
              uid = pnet_id;
              launchables_nb = 0;} in
          let dummy_amd = ref (Reactant.Amol.make_new dummy_pnet)
          in
          !(find dummy_amd amolset).pnet
          
          
        let add_reacs_with_new_reactant (new_reactant : Reactant.t) (amolset :t) reac_mgr : unit =
          if is_empty amolset
          then
            ()
          else
            let (any_amd : Reactant.Amol.t ref) = any amolset in
            let dummy_pnet = !(any_amd).pnet in
            
            match new_reactant with
            | Amol new_amol ->
               
               let is_graber = Petri_net.can_grab
                                 (Reactant.mol new_reactant)
                                 dummy_pnet
               and is_grabed = Petri_net.can_grab
                                dummy_pnet.mol
                                !new_amol.pnet  in
               
               iter
                 (fun current_amd ->
                   if is_graber
                   then
                     Reac_mgr.add_grab new_amol (Amol current_amd) reac_mgr;
                   
                   if is_grabed
                   then 
                     Reac_mgr.add_grab current_amd new_reactant reac_mgr;
                 ) amolset;
               
            | ImolSet _ -> 
               if Petri_net.can_grab (Reactant.mol new_reactant) dummy_pnet
               then 
                 
                 iter
                   (fun current_amol ->
                     Reac_mgr.add_grab current_amol new_reactant reac_mgr)
                   amolset
               
      end

      
    type t = AmolSet.t MolMap.t ref
           
    let add (areactant :Reactant.Amol.t ref)  (armap : t) : Reacs.effect list =
      armap :=
        MolMap.modify_opt
          !areactant.mol
          (fun data ->
            match data with
            | Some amolset ->
               Some ( AmolSet.add areactant amolset )
            | None ->
               Some( AmolSet.singleton areactant )
          ) !armap;
      (* we should return the list of reactions to update *)
      [ Reacs.Update_reacs !((!areactant).reacs)]

      
      
    let remove (areactant : Reactant.Amol.t ref) (armap : t) : Reacs.effect list =
      armap :=
        MolMap.modify
          !areactant.mol
          (fun  amolset ->  AmolSet.remove areactant amolset )
          !armap;
        
      [ Reacs.Remove_reacs !((!areactant).reacs)]
      
    let get_pnet_ids mol (armap :t) =
      MolMap.find mol !armap
      |> AmolSet.enum
      |> Enum.map  (fun (amd : Reactant.Amol.t ref) ->
             (!amd).pnet.uid)
      |> List.of_enum

    let find_pnet mol pnet_id (armap : t) : Petri_net.t =
      MolMap.find mol !armap
      |> AmolSet.find_by_id pnet_id
      
      
    let add_reacs_with_new_reactant (new_reactant : Reactant.t)
                                    (armap :t)  reac_mgr: unit =
      
      MolMap.iter 
        (fun _ areac -> 
          AmolSet.add_reacs_with_new_reactant
            new_reactant
            areac
            reac_mgr)
        !armap
      
  end

(* ** module to interact with inert reactants *)

module IRMap =
  struct
    type t = (Reactant.ImolSet.t) MolMap.t ref

           
    let add_to_qtt (ir : Reactant.ImolSet.t) deltaqtt (irmap : t)
        : Reacs.effect list =
      irmap :=
        MolMap.modify
          ir.mol
          (fun  imolset -> Reactant.ImolSet.add_to_qtt deltaqtt imolset)
          !irmap;
      [Reacs.Update_reacs !(ir.reacs)]
      
    let set_qtt qtt mol (irmap : t)  : Reacs.effect list= 
      let ir = MolMap.find mol !irmap in
      irmap :=
        MolMap.modify
          ir.mol
          (fun  imolset -> Reactant.ImolSet.set_qtt qtt imolset)
          !irmap;
      [ Reacs.Update_reacs !(ir.reacs)]
      
    let set_ambient ambient mol irmap =
      irmap :=
        MolMap.modify
          mol
          (fun  imolset -> Reactant.ImolSet.set_ambient ambient imolset)
          !irmap
      
      
    let remove_all mol (irmap : t) =
      let old_reacs = ref ReacSet.empty
      and old_qtt = ref 0 in
      irmap :=
        MolMap.modify_opt
          mol
          (fun data ->
            match data with
            | None -> failwith "container: cannot remove absent molecule"
            | Some imd ->
               old_reacs := Reactant.ImolSet.reacs imd;
               old_qtt := Reactant.ImolSet.qtt imd;
               None)
          !irmap;
      
      [ Reacs.Remove_reacs !old_reacs]

    let remove_one ir (irmap : t) =
      add_to_qtt ir (-1) irmap
      
    let add_reacs_with_new_reactant (new_reactant : Reactant.t)
                                    (irmap :t) reac_mgr =      
      match new_reactant with
      | Amol new_amol -> 
         MolMap.iter
           (fun mol ireactant ->
             if Petri_net.can_grab mol !new_amol.pnet
             then Reac_mgr.add_grab new_amol new_reactant reac_mgr)
           !irmap
        
      | ImolSet _ -> ()
      
        
  end
  
