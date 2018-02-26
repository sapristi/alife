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
  include PnetSet

  let qtt amolset = PnetSet.cardinal amolset
        
  let find_by_pnet_id pid amolset : Petri_net.t= 
    let (dummy_pnet : Petri_net.t) ={
        mol = ""; transitions = [||];places = [||];
        uid = pid;
        binders = []; launchables_nb = 0;} in
    let dummy_amd = ref (Reactant.Amol.make_new dummy_pnet)
    in
    !(find dummy_amd amolset).pnet
    

  let  get_pnet_ids amolset : int list =
    let pnet_enum = enum amolset in
    let ids_enum = Enum.map
                     (fun (amd : Reactant.Amol.t ref) ->
                       (!amd).pnet.uid) pnet_enum in
    List.of_enum ids_enum
    
  let random_pick amolset =
    let c = cardinal amolset in
    let n = Random.int c in at_rank_exn n amolset
        
(* *** update reacs with new reactant *)
(* Calculates the possible reactions with a reactant *)
      
  let add_reacs_with_new_reactant (new_reactant : Reactant.t) amolset reac_mgr =
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
           ) amolset;
         

      | ImolSet _ -> 
         if Petri_net.can_grab (Reactant.mol new_reactant) dummy_pnet
         then 
      
           PnetSet.iter
             (fun current_amol ->
               Reac_mgr.add_grab current_amol new_reactant reac_mgr)
             amolset
      
      
end
module MolMap = Map.Make (struct type t = Molecule.t
                                 let compare = Pervasives.compare end)

module ActiveReactants =
  struct
    include MolMap
    type elt = ActiveMolSet.t
    
    let random_AR_pick (areactants : elt t)=
      let total_qtt =
        float_of_int (
            fold
              (fun _ (amolset :elt) (res:int) ->
                (ActiveMolSet.qtt amolset) + res)
              areactants 0)
      in
      let b = Random.float total_qtt in
      let amolset = 
        Misc_library.pick_from_enum
        b 
        (fun amols -> float_of_int (ActiveMolSet.qtt amols))
        (values areactants)
      in ActiveMolSet.random_pick amolset
  end
  
module InertReactants =
  struct
    include MolMap
    type elt = Reactant.ImolSet.t ref

    let random_pick (ireactants : elt t) =
      let total_qtt =
        float_of_int (
            fold
              (fun _ (imolset :elt) (res:int) ->
                (Reactant.ImolSet.qtt !imolset) + res)
              ireactants 0)
      in
      let b = Random.float total_qtt in
          Misc_library.pick_from_enum
            b
            (fun imols -> float_of_int (Reactant.ImolSet.qtt !imols))
            (values ireactants)
             
  end
