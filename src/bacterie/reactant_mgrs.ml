open Reaction
open Batteries

module MolSet =
  struct
    include Set.Make (struct type t = Molecule.t
                             let compare = Pervasives.compare end)
                     (* include Exceptionless *)
      
  end

(* ** ActiveMolSet *)
(* An active mol set manages the molecules with an attached pnet. *)
(* this should eventually be moved to reactant.ml *)
module ActiveMolSet  = struct

  module PnetSet =
    Set.Make (
        struct
          type t = Reactant.Amol.t ref
          let compare =
            fun (amd1 :t) (amd2:t) ->
            Reactant.Amol.compare
              !amd1 !amd2
        end)

  type t =
    { mutable pnets : PnetSet.t;
      mol : Molecule.t;
      reacs : ReacSet.t}

  let make_new mol : t =
    {pnets = PnetSet.empty;
     mol; reacs = ReacSet.empty;}
    
  let qtt (aset :t) = PnetSet.cardinal aset.pnets
  let mol (aset :t) = aset.mol
               
  let find_by_pnet_id pid (aset :t) : Petri_net.t= 
    let (dummy_pnet : Petri_net.t) ={
        mol = ""; transitions = [||];places = [||];
        uid = pid;
        binders = []; launchables_nb = 0;} in
    let dummy_amd = ref (Reactant.Amol.make_new dummy_pnet)
    in
    !(PnetSet.find dummy_amd aset.pnets).pnet
    

  let  get_pnet_ids (aset :t): int list =
    let pnet_enum = PnetSet.enum aset.pnets in
    let ids_enum = Enum.map
                     (fun (amd : Reactant.Amol.t ref) ->
                       (!amd).pnet.uid) pnet_enum in
    List.of_enum ids_enum
    
  let random_pick (aset :t) =
    let c = PnetSet.cardinal aset.pnets in
    let n = Random.int c in PnetSet.at_rank_exn n aset.pnets
        
(* *** update reacs with new reactant *)
(* Calculates the possible reactions with a reactant *)
      
  let add_reacs_with_new_reactant (new_reactant : Reactant.t) (aset :t) reac_mgr =
    if PnetSet.is_empty aset.pnets
    then
      ()
    else
      let (any_amd : Reactant.Amol.t ref) = PnetSet.any aset.pnets in
      let dummy_pnet = !(any_amd).pnet in

      match new_reactant with
      | Amol new_amol ->
         
         let is_graber = Petri_net.can_grab
                           (Reactant.mol new_reactant)
                           dummy_pnet
         and is_grabed =Petri_net.can_grab
                          dummy_pnet.mol
                          !new_amol.pnet  in
         

         PnetSet.iter
           (fun current_amd ->
             if is_graber
             then
               Reac_mgr.add_grab new_amol (Amol current_amd) reac_mgr;
             
             if is_grabed
             then 
               Reac_mgr.add_grab current_amd new_reactant reac_mgr;
           ) aset.pnets;
         
         
      | ImolSet _ -> 
         if Petri_net.can_grab (Reactant.mol new_reactant) dummy_pnet
         then 
           
           PnetSet.iter
             (fun current_amol ->
               Reac_mgr.add_grab current_amol new_reactant reac_mgr)
             aset.pnets
         
      
end
module MolMap = Map.Make (struct type t = Molecule.t
                                 let compare = Pervasives.compare end)

module ActiveReactantsMgr =
  struct
    type t =
      { mutable reactants : (ActiveMolSet.t) MolMap.t;}

    let empty = {reactants = MolMap.empty;}
      
    let qtt areacts_mgr =
      MolMap.fold
        (fun _ amolset res -> ActiveMolSet.qtt amolset + res)
        areacts_mgr.reactants 0
      
    let random_AR_pick (areactants_mgr : t)=
      let b = Random.float (float_of_int (qtt areactants_mgr)) in
      let (amolset : ActiveMolSet.t) = 
        Misc_library.pick_from_enum
          b 
          (fun amols -> float_of_int (ActiveMolSet.qtt amols))
          (MolMap.values areactants_mgr.reactants)
      in ActiveMolSet.random_pick amolset
  end
  
module InertReactantsMgr =
  struct
    type t =
      { mutable reactants : (Reactant.ImolSet.t ref) MolMap.t;}
      
    let empty = {reactants = MolMap.empty;}
    let qtt (ireacts_mgr:t) =
      MolMap.fold
        (fun _ imolset res -> Reactant.ImolSet.qtt !imolset + res)
        ireacts_mgr.reactants 0
      
    let random_pick (ireacs_mgr : t) =
      
      let b = Random.float (float_of_int (qtt ireacs_mgr)) in
          Misc_library.pick_from_enum
            b
            (fun imols -> float_of_int (Reactant.ImolSet.qtt !imols))
            (MolMap.values ireacs_mgr.reactants)
             
  end

       
