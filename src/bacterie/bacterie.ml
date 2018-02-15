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
open Maps
open Batteries
open Reacs_mgr
open Reaction
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

(* Afin d'améliorer ça, on peut : *)
(*  - passer en n² + something *)
(*    (où n est le nombre de molécules différentes) *)
(*    en déterminant la probabilité de deux espèces de se *)
(*    rencontrer, puis la paire précise de molécules qui vont *)
(*    réagir, et enfin quelle réaction va avoir lieu *)
(*  - On peut aussi stoquer pour chaque molécule l'ensemble *)
(*    des molécules avec lesquelles elle peut réagir, *)
(*    qui est pas mal puisque la plupart des molécules *)
(*    ne vont pas réagir avec beaucoup d'autres. *)
(*    Afin d'accélérer la création de cet ensemble, *)
(*    on pourrait garder les binders et grabers map, *)
(*    mais pour l'instant je vais les virer pour que ce soit *)
(*    plus simple *)

(*    Bon en fait le problème c'est que les ensembles ne sont pas *)
(*    symétriques *)
(*    (mol.reactants = { mol' tq  can_bind mol'.pnet mol.pnet *)
(*                             OU can_grab mol' mol.pnet } ) *)
(*    Si on faisait un ensemble symétrique, on aurait tout en double. *)

(*    Du coup la solution ce serait d'avoir : *)
(*    (mol.reactants = { mol' tq mol' < mol   ET *)
(*                             (   can_bind mol'.pnet mol.pnet *)
(*                             OU  can_grab mol  mol'.pnet *)
(*                             OU  can_grab mol' mol.pnet )} ) *)
(*    ou plus simplement *)
(*    (mol.reactants = { mol' tq mol' <= mol *)
(*                            ET can_react mol mol'}) *)

(*    MAIS *)

(*    si on veut pouvoir simplifier avec les molécules qui n'ont *)
(*    pas de pnet, il faudra avoir deux sets de reactives : *)
(*    + un comme précédemment (donc seulement les mol' < mol) *)
(*      pour les molécules qui ont un PNet *)
(*    + un second qui ne contient que des molécules qui *)
(*      n'ont pas de PNet *)


(* - il faudrait aussi stoquer séparement les molécules qui n'ont *)
(*   pas de réseau de pétri (ou des réseaux dégénérés) *)


(* Autre idée : construire un arbre des réactions (pas complètement *)
(* un arbre mais presque). *)
(* Les feuilles sont les molécules. *)
(* Pour chaque réaction, un nœud est créé comme étant un parent *)
(* des molécules impliquées. Quand une molécule change *)
(* (changement du pnet, changement des quantités), il suffit  *)
(* de parcourir l'arbre vers la racine pour mettre à jour les taux de réaction. *)




(* ** types *)

type active_md = Reaction.active_md = { mol : Molecule.t;
                                  pnet : Petri_net.t ref;
                                  reacs : ReacsSet.t ref; }
type inert_md = Reaction.inert_md = {   mol : Molecule.t;
                                   qtt : int ref; 
                                   reacs : ReacsSet.t ref; }
module MolMap =
  Map.Make (struct type t = Molecule.t
                   let compare = Pervasives.compare
            end)
  
  
module MolSet =
  Set.Make (struct type t = Molecule.t
                   let compare = Pervasives.compare
            end)
  

(* ** ActiveMolSet *)
(* An active mol set manages the molecules with an attached pnet. *)
   
module ActiveMolSet  = struct

  module PnetSet =
    Set.Make (
        struct
          type t = active_md
          let compare =
            fun (amd1 :t) (amd2:t) ->
            Pervasives.compare
              !(amd1.pnet).uid !(amd2.pnet).uid
        end)
  include PnetSet
        
  let find_by_pnet_id pid amolset : Petri_net.t= 
    let (dummy_pnet : Petri_net.t) ={
        mol = ""; transitions = [||];places = [||];
        uid = pid;
        binders = []; launchables_nb = 0;} in
    let dummy_amd = Reaction.make_new_active_md (ref dummy_pnet)
    in
    !((find dummy_amd amolset).pnet)
    

  let  get_pnet_ids amolset : int list =
    let pnet_enum = enum amolset in
    let ids_enum = Enum.map
                     (fun (amd : Reaction.active_md) ->
                       !(amd.pnet).Petri_net.uid) pnet_enum in
    List.of_enum ids_enum
    

        
(* *** update reacs with mol *)
(* Calculates the possible reactions with an *)
(* inert molecule *)
      
  let add_reacs_with_new_mol (new_inert_md : Reaction.inert_md) amolset reacs_mgr =
    if is_empty amolset
    then
      ()
    else
      let (any_amd : active_md) = any amolset in
      let dummy_pnet = !(any_amd.pnet) in
      if Petri_net.can_grab new_inert_md.mol dummy_pnet
      then
        PnetSet.iter
          (fun graber_d ->
            Reacs_mgr.add_grab graber_d new_inert_md reacs_mgr)
          amolset
      

  let add_reacs_with_new_pnet (new_active_md : active_md)
                              amolset
                              reacs_mgr =
    if is_empty amolset
    then
      ()
    else
      let (any_amd : active_md) = any amolset in
      let dummy_pnet = !(any_amd.pnet) in
      
      (* the new pnet is grabed *)
      let is_graber = Petri_net.can_grab new_active_md.mol dummy_pnet
      and is_grabed = Petri_net.can_grab dummy_pnet.mol !(new_active_md.pnet)
      in
      if (is_graber || is_grabed)
      then 
        PnetSet.iter
          (fun current_amd ->
            if is_graber
            then
              Reacs_mgr.add_agrab new_active_md current_amd reacs_mgr;
            
            if is_grabed
            then 
              Reacs_mgr.add_agrab current_amd new_active_md reacs_mgr;
          ) amolset;
      
end
                       
type t =
  {mutable inert_molecules : (inert_md) MolMap.t;
   mutable active_molecules : (ActiveMolSet.t) MolMap.t;
   reacs_mgr : Reacs_mgr.t;
  }
  
(* ** interface *)
  
(* Whenever modifying the bactery, it should be *)
(* done through these functions alone *)

(* *** make empty *)
(* an empty bactery *)
let make_empty () : t = 
  {inert_molecules =  MolMap.empty;
   active_molecules = MolMap.empty;
   reacs_mgr = Reacs_mgr.make_new ();}
  
(* *** add new molecule *)
(* adds a new molecule inside a bactery *)
(* on peut sûrement améliorer le bouzin, mais pour l'instant on se prends pas la tête *)
let add_new_molecule (new_mol : Molecule.t) (bact : t) : unit =
  
  let new_opnet = Petri_net.make_from_mol new_mol
  in
  match new_opnet with
  | None ->
     let new_inert_md = Reaction.make_new_inert_md new_mol (ref 1) in
     
     MolMap.iter
       (fun mol amolset ->
         ActiveMolSet.add_reacs_with_new_mol
           new_inert_md amolset bact.reacs_mgr)
       bact.active_molecules;
     
     bact.inert_molecules <-
       MolMap.add new_mol
                  new_inert_md
                  bact.inert_molecules;
     
  | Some new_pnet ->
     let new_active_md = Reaction.make_new_active_md (ref new_pnet) in
     
     (* adding agrabs with active molecules *)
     MolMap.iter
       (fun mol amolset ->
         ActiveMolSet.add_reacs_with_new_pnet
           new_active_md amolset bact.reacs_mgr)
       bact.active_molecules;
     
     (
       (* adding grabs with inert molecules *)
       MolMap.iter
         (fun mol grabed_d ->
           if Petri_net.can_grab mol new_pnet
           then
             Reacs_mgr.add_grab new_active_md grabed_d bact.reacs_mgr;
             
         ) bact.inert_molecules;
       
       (* adding the transition reaction *)
       Reacs_mgr.add_transition new_active_md bact.reacs_mgr 
     );
     
     (* adding the molecule to the bactery *)
     bact.active_molecules <-
       MolMap.modify_opt
         new_mol
         (fun data ->
           match data with
           | Some amolset ->
              Some (ActiveMolSet.add new_active_md amolset)
           | None ->
              Some (ActiveMolSet.singleton new_active_md))
         bact.active_molecules
     

     

           
(* *** update reaction rates *)

(* Update the rates of all the reactions implicating *)
(* a molecule                      *)

let update_rates reactions bact =
  ReacsSet.iter
    (fun reac ->
      Reacs_mgr.update_reaction_rates reac bact.reacs_mgr)
    reactions

  
(* *** set mol quantity *)
(* changes the number of items of a particular molecule *)
let set_inert_mol_quantity (mol : Molecule.t) (n : int) (bact : t) =
  if MolMap.mem mol bact.inert_molecules
  then
    let {qtt = qtt; reacs = reacs; _} = MolMap.find mol bact.inert_molecules in
    qtt := n;
    update_rates !reacs bact
  else
    failwith ("bacterie.ml : update_mol_quantity :  target molecule is not present\n"  ^mol)

let add_inert_mol_quantity (mol : Molecule.t) (n : int) (bact : t) : unit= 
  if MolMap.mem mol bact.inert_molecules
  then
    (
      let {qtt = qtt; reacs= reacs;_} = MolMap.find mol bact.inert_molecules in
      qtt := !qtt + n;
      update_rates !reacs bact
    )
  else
    failwith ("bacterie.ml : add_mol_quantity :  target molecule is not present\n"
              ^mol)
  
(* *** remove molecule *)
(* totally removes a molecule from a bactery *)
(* TODO : update reactives *)

let remove_molecule (m : Molecule.t) (bact : t) : unit =
  let old_reacs = ref ReacsSet.empty
  in
  bact.inert_molecules <-
    MolMap.modify_opt
      m
      (fun data ->
        match data with
        | None -> failwith "container: cannot remove absent molecule"
        | Some imd ->
           old_reacs := !(imd.reacs);
           None)
      bact.inert_molecules;
  update_rates !old_reacs bact;
  Reacs_mgr.remove_reactions !old_reacs bact.reacs_mgr

(* *** add_molecule *)
(* adds a molecule inside a bactery *)
(* on peut sûrement améliorer le bouzin, mais pour l'instant on se prends pas la tête *)
let add_molecule (mol : Molecule.t) (bact : t) : unit =
  
  if MolMap.mem mol bact.inert_molecules
  then 
    add_inert_mol_quantity mol 1 bact
  else
    add_new_molecule mol bact


(* *** add_proteine *)
(* adds the molecule corresponding to a proteine to a bactery first transforms it back to a molecule, so the *)
(* process is not very natural. *)
(* ***** SHOULD NOT BE USED *)

let add_proteine (prot : Proteine.t) (bact : t) : unit =
  let mol = Molecule.of_proteine prot in
  add_molecule mol bact


(* ** simulation ; new *)
   
(*    This part takes care of simulating what happens inside *)
(*    a bactery (or more generally any container). *)

(*    Possible events are : *)
(*    + a transition is launched (possibly with side effects) *)
(*    + two molecules colide *)

(*    The current simulation framework calculates each reaction rate, *)
(*    and then randomly selects the next reaction. *)




(* *** make_reactions *)
(* Reactions between molecules : *)
(* we have to simulate molecules collision, *)
(* then try grabs (and later catch) *)

(* For now, collisions are static and do *)
(* not depend on anything (e.g. the number of molecules) *)

(* **** execute_actions *)
(* after a transition from a proteine has occured, *)
(*    some actions may need to be performed by the bactery *)
(*   for now, only the release effect is in use *)
(*   todo later : ??? *)
(*   il faudrait peut-être mettre dans une file les molécules à ajouter *)

let rec execute_actions (actions : Reaction.reaction_effect list) (bact : t) : unit =
  List.iter
    (fun (effect : Reaction.reaction_effect) ->
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
      | Update reacs ->
         update_rates !reacs bact
      | Remove_pnet pnet ->
         bact.active_molecules <-
           MolMap.modify_opt
             (!pnet).mol
             (fun data ->
               match data with
               | Some amolset ->
                  let dummy_amd = Reaction.make_new_active_md pnet in
                  Some (ActiveMolSet.remove
                          dummy_amd amolset) 
               | None -> None
             ) bact.active_molecules
    )
  actions
                                     
    
let next_reaction (bact : t)  =
  let ro = Reacs_mgr.pick_next_reaction bact.reacs_mgr in
  match ro with
  | None -> failwith "next_reaction @ bacterie : no more reactions"
  | Some r ->
     let actions = Reaction.treat_reaction r in
     execute_actions actions bact


(* ** json serialisation *)
type bact_elem = {nb : int;mol: Molecule.t} 
                   [@@ deriving yojson]
type bact_sig ={
    inert_mols : bact_elem list;
    active_mols : bact_elem list;
  }
                 [@@ deriving yojson]
              
              
let to_json (bact : t) : Yojson.Safe.json =
  let imol_enum = MolMap.enum bact.inert_molecules in
  let trimmed_imol_enum = Enum.map (fun (a,imd) -> {mol=a; nb= !(imd.qtt)}) imol_enum in
  let trimmed_imol_list = List.of_enum trimmed_imol_enum in
  
  let amol_enum = MolMap.enum bact.active_molecules in
  let trimmed_amol_enum =
    Enum.map (fun (a, amolset) ->
        {mol = a; nb = ActiveMolSet.cardinal amolset;})
             amol_enum
  in
  let trimmed_amol_list = List.of_enum trimmed_amol_enum
  in  
    bact_sig_to_yojson {inert_mols = trimmed_imol_list;
                        active_mols = trimmed_amol_list;}
  
  
let json_reset (json : Yojson.Safe.json) (bact:t): unit  =
  match  bact_sig_of_yojson json with
  |Ok bact_sig -> 
    bact.inert_molecules <- MolMap.empty;
    List.iter
      (fun {mol = m;nb = n} ->
        add_molecule m bact;
        set_inert_mol_quantity m n bact;
        print_endline ("added inactive mol: "^m);
      ) bact_sig.inert_mols;
    
    bact.active_molecules <-  MolMap.empty;
    List.iter
      (fun {mol = m; nb = n} ->
        (*        for i = 0 to n do *)
        add_molecule m bact;
                       (*        done; *)
        print_endline ("added active mol: "^m);)
    bact_sig.active_mols
  | Error s -> failwith s
