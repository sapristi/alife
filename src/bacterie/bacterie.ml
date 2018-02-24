(* * this file *)


(*   - on compte combien de molécules identiques de chaque type on a *)
(*    ( ça voudrait dire qu'il faudrait bien les ranger *)
(*    pour vite les retrouver. Mais tout ça c'est pour plus tard) *)

(*   - on crée un petri-net par type de molécule, la vitesse de simulation *)
(*    dépend du nombre de molécules (parce que à la fois c'est plus simple *)
(*    et ça va plus vite, donc on se prive pas) *)

(*   - mais bon ya aussi des molécules qui sont associées à des token *)
(*    (donc faut se souvenir desquelles le sont), et puis aussi créer de *)
(*    nouvelles molécules quand elles apparaissent. *)

(*   - Il faudrait aussi tester rapidement si une molécule a une forme *)
(*    protéinée qui fait quelque chose, pour pas s'embêter avec *)


(* * libs *)
open Misc_library
open Reaction
type ('a, 'b) mresult = ('a, 'b) result
open Batteries
open Molsets
(*   Table d'association où les clés sont des molécule  Permet de stoquer efficacement la protéine associée *)
(*   et le nombre de molécules présentes. *)

(* * Container module *)


(* Une bacterie est un conteneur à molecules. Elle s'occupe de fournir l'interprétation d'une molécule en tant que *)
(* protéine (i.e. pnet), puis d'organiser la simulation des pnet *)
(* et de leurs interactions. *)

(* Pour organiser la simulation, il faut : *)
(*  - organiser le lancement des transitions *)
(*  - gérer les réactions *)

(* Pour rentrer dans le cadre Stochastic Simulations, *)
(* il faut associer à chaque réaction une probabilité. *)
(* Le calcul de la réaction suivante nécéssite de calculer la *)
(* proba de chacune des réactions, ce qui se fait en N² où N *)
(* est le NOMBRE total de molécules (c'est beaucoup trop). *)


(* Autre idée : construire un arbre des réactions (pas complètement *)
(* un arbre mais presque). *)
(* Les feuilles sont les molécules. *)
(* Pour chaque réaction, un nœud est créé comme étant un parent *)
(* des molécules impliquées. Quand une molécule change *)
(* (changement du pnet, changement des quantités), il suffit  *)
(* de parcourir l'arbre vers la racine pour mettre à jour les taux de réaction. *)




(* ** types *)

              
module MolMap =
  struct
    include Map.Make (struct type t = Molecule.t
                             let compare = Pervasives.compare end)
                     (*   include Exceptionless *)
  end
  
  
type t =
  {mutable inert_molecules : (Reactant.ImolSet.t ref) MolMap.t;
   mutable active_molecules : (ActiveMolSet.t) MolMap.t;
   reac_mgr : Reac_mgr.t;
  }
  
(* ** interface *)
  
(* Whenever modifying the bactery, it should be *)
(* done through these functions alone *)

(* *** make empty *)
(* an empty bactery *)
  
let (default_rcfg : Reac_mgr.config) =
  {transition_rate = 10.;
   grab_rate = 1.;
   break_rate = 0.0001}
  
let make_empty ?(rcfg=default_rcfg) () = 
  {inert_molecules =  MolMap.empty;
   active_molecules = MolMap.empty;
   reac_mgr = Reac_mgr.make_new rcfg}

             
(* *** add new molecule *)
(* adds a new molecule inside a bactery *)

let add_inert_mol ?(ambient=false) (new_mol : Molecule.t) (bact : t) : unit = 
  
  let new_inert_md = ref (Reactant.ImolSet.make_new ~ambient:ambient new_mol) in
  
  (* reactions : grab  by active mols *)
  MolMap.iter
    (fun mol amolset ->
      ActiveMolSet.add_reacs_with_new_reactant
        (ImolSet new_inert_md) amolset bact.reac_mgr)
    bact.active_molecules;
  
  (* reactions : break *)
  Reac_mgr.add_break (ImolSet new_inert_md) bact.reac_mgr;
  
  (* add to bactery *)
  bact.inert_molecules <-
    MolMap.add new_mol
               new_inert_md
               bact.inert_molecules

     
let add_new_molecule (new_mol : Molecule.t) (bact : t) : unit =
  
  let new_opnet = Petri_net.make_from_mol new_mol
  in
  match new_opnet with
  | None ->
     add_inert_mol new_mol bact
  | Some new_pnet ->
     let new_active_md = ref (Reactant.Amol.make_new new_pnet) in
     
     (* reactions :  grabs with active molecules *)
     MolMap.iter
       (fun mol amolset ->
         ActiveMolSet.add_reacs_with_new_reactant
           (Amol new_active_md) amolset bact.reac_mgr)
       bact.active_molecules;
     
     (* reactions : grabs with inert molecules *)
     MolMap.iter
       (fun mol grabed_d ->
         if Petri_net.can_grab mol new_pnet
         then
           Reac_mgr.add_grab new_active_md
                             (ImolSet grabed_d)
                             bact.reac_mgr;
         ) bact.inert_molecules;
     
     (* reaction : transition  *)
     Reac_mgr.add_transition new_active_md bact.reac_mgr;
     
     (* reaction : break *)
     Reac_mgr.add_break (Amol new_active_md) bact.reac_mgr;
     (* adding to the bactery *)
     print_endline "adding mol";
     bact.active_molecules <-
       MolMap.modify_opt
         new_mol
         (fun data ->
           match data with
           | Some amolset ->
              let new_amolset = ActiveMolSet.add new_active_md amolset
              in
              Some (new_amolset)
           | None ->
              Some (ActiveMolSet.singleton new_active_md))
         bact.active_molecules;
     print_endline "mol added"

     

           
(* *** update reaction rates *)

(* Update the rates of all the reactions implicating *)
(* a molecule                      *)

let update_rates (reactions : ReacSet.t) bact =
  ReacSet.iter
    (fun reac ->
      Reac_mgr.update_reaction_rates reac bact.reac_mgr)
    reactions

(* *** remove molecule *)
(* totally removes a molecule from a bactery *)

let remove_molecule (m : Molecule.t) (bact : t) : unit =
  let old_reacs = ref ReacSet.empty
  in
  bact.inert_molecules <-
    MolMap.modify_opt
      m
      (fun data ->
        match data with
        | None -> failwith "container: cannot remove absent molecule"
        | Some imd ->
           old_reacs := Reactant.ImolSet.reacs !imd;
           None)
      bact.inert_molecules;
  update_rates !old_reacs bact;
  Reac_mgr.remove_reactions !old_reacs bact.reac_mgr
  
(* *** add_molecule *)
(* adds a molecule inside a bactery *)
(* on peut sûrement améliorer le bouzin, mais pour l'instant on se prends pas la tête *)
let add_molecule (mol : Molecule.t) (bact : t) : unit =
  match MolMap.Exceptionless.find mol bact.inert_molecules with
  | Some ims -> ims := Reactant.ImolSet.add_to_qtt 1 !ims
  | None -> add_new_molecule mol bact


(* **** execute_actions *)
(* after a transition from a proteine has occured, *)
(*    some actions may need to be performed by the bactery *)
(*   for now, only the release effect is in use *)
(*   todo later : ??? *)
(*   il faudrait peut-être mettre dans une file les molécules à ajouter *)

let rec execute_actions (actions : Reacs.effect list) (bact : t) : unit =
  List.iter
    (fun (effect : Reacs.effect) ->
      match effect with
      | T_effects tel ->
         List.iter
           (fun teffect ->
             match teffect with
             | Place.Release_effect mol  ->
                if mol != ""
                then add_molecule mol bact
             | Place.Message_effect m  ->
             (* bact.message_queue <- m :: bact.message_queue; *)
                ()
           ) tel
      | Update_reacs reacset ->
         update_rates reacset bact
      | Remove_one reactant ->
         (
           match reactant with
           | ImolSet ims -> ims := Reactant.ImolSet.add_to_qtt (-1) !ims
           | Amol amol ->
              let old_reacs = Reactant.Amol.reacs !amol in
              bact.active_molecules <-
                MolMap.modify_opt
                  (Reactant.Amol.mol !amol)
                  (fun data ->
                    match data with
                    | Some amolset ->
                     Some (ActiveMolSet.remove
                             amol amolset)
                    | None -> None
                  ) bact.active_molecules;
              
         )
      | Release_mol mol -> add_molecule mol bact
      | Release_tokens tlist ->
         List.iter (fun (n,mol) ->
             add_new_molecule mol bact) tlist
    )
    actions
  
  
let next_reaction (bact : t)  =
  let ro = Reac_mgr.pick_next_reaction bact.reac_mgr in
  match ro with
  | None -> failwith "next_reaction @ bacterie : no more reactions"
  | Some r ->
     let actions = Reaction.treat_reaction r in
     execute_actions actions bact

let set_inert_mol_quantity mol n bact =
  let imd = MolMap.find mol bact.inert_molecules in
  imd := Reactant.ImolSet.set_qtt n !imd

  
              
(* ** json serialisation *)
type inert_bact_elem = {qtt:int;mol: Molecule.t;ambient:bool}
                     [@@ deriving yojson]
type active_bact_elem = {qtt:int;mol: Molecule.t} 
                   [@@ deriving yojson]
type bact_sig = {
    inert_mols : inert_bact_elem list;
    active_mols : active_bact_elem list;
  }
                 [@@ deriving yojson]
              
let make (bact_sig : bact_sig) :t  = 
  let bact = make_empty () in
  bact.inert_molecules <- MolMap.empty;
  List.iter
    (fun {mol = m;qtt = n; ambient=a} ->
      add_inert_mol ~ambient:a m bact;
      set_inert_mol_quantity m n bact;
    ) bact_sig.inert_mols;
  
  bact.active_molecules <-  MolMap.empty;
  List.iter
    (fun {mol = m; qtt = n} ->
      for i = 0 to n-1 do 
        add_molecule m bact;
      done;)
    bact_sig.active_mols;
  bact

  
let to_yojson (bact : t) : Yojson.Safe.json =
  let imol_enum = MolMap.enum bact.inert_molecules in
  let trimmed_imol_enum =
    Enum.map (fun (a,(imd: Reactant.ImolSet.t ref)) ->
        ({mol= !imd.mol; qtt= !imd.qtt;
          ambient= !imd.ambient} : inert_bact_elem))
             imol_enum in
  let trimmed_imol_list = List.of_enum trimmed_imol_enum in
  
  let amol_enum = MolMap.enum bact.active_molecules in
  let trimmed_amol_enum =
    Enum.map (fun (a, amolset) ->
        {mol = a; qtt = ActiveMolSet.cardinal amolset;})
             amol_enum
  in
  let trimmed_amol_list = List.of_enum trimmed_amol_enum
  in  
  bact_sig_to_yojson {inert_mols = trimmed_imol_list;
                      active_mols = trimmed_amol_list;}


let of_yojson (json : Yojson.Safe.json) : (t,string) mresult =
  match  bact_sig_of_yojson json with
  | Ok bact_sig -> Ok (make bact_sig)
  | Error s -> (Error s)
             
  
module SimControl =
  struct
    
(* *** set mol quantity *)
(* changes the number of items of a particular molecule *)
    let set_inert_mol_quantity (mol : Molecule.t) (n : int) (bact : t) =
      if MolMap.mem mol bact.inert_molecules
      then
        let ims = MolMap.find mol bact.inert_molecules in
        ims := Reactant.ImolSet.set_qtt n !ims;
        update_rates (Reactant.ImolSet.reacs !ims) bact
      else
        failwith ("bacterie.ml : update_mol_quantity :  target molecule is not present\n"  ^mol)
      
(* *** add_proteine *)
(* adds the molecule corresponding to a proteine to a bactery first transforms it back to a molecule, so the *)
(* process is not very natural. *)
(* ***** SHOULD NOT BE USED *)

    let add_proteine (prot : Proteine.t) (bact : t) : unit =
      let mol = Molecule.of_proteine prot in
      add_molecule mol bact

    
end
