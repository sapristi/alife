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
  let find_by_pnet_id pid amolset : Petri_net.t= 
    let (dummy_pnet : Petri_net.t) ={
        mol = ""; transitions = [||];places = [||];
        uid = pid;
        binders = []; launchables_nb = 0;} in
    let dummy_amd = ref (Reactant.Amol.make_new dummy_pnet)
    in
    Reactant.Amol.pnet !(find dummy_amd amolset)
    

  let  get_pnet_ids amolset : int list =
    let pnet_enum = enum amolset in
    let ids_enum = Enum.map
                     (fun (amd : Reactant.Amol.t ref) ->
                       (Reactant.Amol.pnet !amd).uid) pnet_enum in
    List.of_enum ids_enum
    

        
(* *** update reacs with new reactant *)
(* Calculates the possible reactions with a reactant *)
      
  let add_reacs_with_new_reactant (new_reactant : Reactant.t) amolset reac_mgr =
    if is_empty amolset
    then
      ()
    else
      let (any_amd : Reactant.Amol.t ref) = any amolset in
      let dummy_pnet = Reactant.Amol.pnet !(any_amd) in

      match new_reactant with
      | Amol new_amol ->
         
         let is_graber = Petri_net.can_grab (Reactant.mol new_reactant) dummy_pnet
         and is_grabed =Petri_net.can_grab dummy_pnet.mol (Reactant.Amol.pnet !new_amol)  in
         

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


module InertMolSet =
  struct
    type t = Reactant.ImolSet.t ref * bool
          
           
    let qtt ((ims,_):t) = Reactant.ImolSet.qtt !ims
    let mol ((ims,_):t) = Reactant.ImolSet.mol !ims

    let add_to_qtt deltaqtt ((ims,c):t) =
      if (not c) then
        ims := Reactant.ImolSet.add_to_qtt deltaqtt !ims
    
    
  end
