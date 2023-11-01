open Reaction
open Base_chemistry

module MolSet = struct
  include Local_libs.Set.Make (Molecule)
  (* include Exceptionless *)
end

(* ** ActiveMolSet *)
(* An active mol set manages the molecules with an attached pnet. *)

module ActiveMolSet = struct
  include Local_libs.Set.Make (Reactant.Amol)

  let find_by_pnet_id pid amolset : Petri_net.t =
    let (dummy_pnet : Petri_net.t) =
      {
        mol = "";
        transitions = [||];
        places = [||];
        uid = pid;
        launchables_nb = 0;
      }
    in
    let dummy_amd = Reactant.Amol.make_new dummy_pnet in
    (find dummy_amd amolset).pnet

  let get_pnet_ids amolset : int list =
    let pnet_enum = to_list amolset in
    List.map (fun (amd : Reactant.Amol.t) -> amd.pnet.uid) pnet_enum

  (* *** update reacs with new reactant *)
  (* Calculates the possible reactions with a reactant *)

  let add_reacs_with_new_reactant (new_reactant : Reactant.t) amolset reac_mgr =
    if is_empty amolset then ()
    else
      let (any_amd : Reactant.Amol.t) = choose amolset in
      let dummy_pnet = any_amd.pnet in

      match new_reactant with
      | Dummy -> failwith "dummy"
      | Amol new_amol ->
          let is_graber =
            Petri_net.can_grab (Reactant.mol new_reactant) dummy_pnet
          and is_grabed = Petri_net.can_grab dummy_pnet.mol new_amol.pnet in

          iter
            (fun current_amd ->
              if is_graber then
                Reac_mgr.add_grab new_amol (Amol current_amd) reac_mgr;

              if is_grabed then
                Reac_mgr.add_grab current_amd new_reactant reac_mgr)
            amolset
      | ImolSet _ ->
          if Petri_net.can_grab (Reactant.mol new_reactant) dummy_pnet then
            iter
              (fun current_amol ->
                Reac_mgr.add_grab current_amol new_reactant reac_mgr)
              amolset
end
