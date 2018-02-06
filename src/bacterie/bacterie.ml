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

              
module MolMap = Map.Make (struct type t = Molecule.t
                                 let compare = Pervasives.compare
                          end)
              
              
module MolSet = Set.Make (struct type t = Molecule.t
                                 let compare = Pervasives.compare
                          end)
              

(* ** ActiveMolSet *)
(* An active mol set manages the molecules with an attached pnet. *)
(*  - quantity : mol quantity *)
(*  - dummy_pnet : an associated pnet that will not be used during *)
(*    the simulation, but only to calculate possible reactions *)
(*    with new molecules (we could do without, but it may be a bit *)
(*    more elegant) *)
(*  - reacs : reactions involving the pnets as inactive molecules  *)
(*    (grabs) *)
(*  - pnet : a set of pnet ref  * reacs set ref, with as many *)
(*    elements as quantity *)
   
module ActiveMolSet  = struct

  module PnetSet = Set.Make (
                             struct
                               type t = (Petri_net.t ref * Reacs_mgr.reacsSet ref)
                               let compare =
                                 fun ((p1,_) :t) ((p2,_):t) ->
                                 Pervasives.compare !p1.uid !p2.uid
                             end)
                 
  type t = {
      dummy_pnet : Petri_net.t;
      reacs : reacsSet ref;
      pnets : PnetSet.t;
    }
         
  let make_empty mol pnet : t =
       {
         dummy_pnet = pnet;
         reacs = ref Set.empty;
         pnets = PnetSet.empty;
       }
(* *** update reacs with mol *)
(* Calculates the possible reactions with an *)
(* inactive molecule *)
      
  let add_reacs_with_new_mol (new_mol : Molecule.t)
                            (new_molqtt : int ref)
                            molreacs amolset reacs_mgr =
    
    if Petri_net.can_grab new_mol amolset.dummy_pnet
    then
      let (grabed_d : Reacs_mgr.inactive_mol_data) = { mol = new_mol;
                  qtt = new_molqtt;
                  reacs = molreacs;
                }
      in
      PnetSet.iter
        (fun (pnet, reacs) ->
          let graber_d = { mol = amolset.dummy_pnet.mol;
                      pnet = pnet;
                      reacs = reacs;}
          in
          let new_grab = 
            Reacs_mgr.add_grab graber_d grabed_d reacs_mgr in
          reacs := Set.add new_grab !reacs;
          molreacs := Set.add new_grab !molreacs
        ) amolset.pnets


  let add_reacs_with_new_pnet (new_mol : Molecule.t)
                             (new_pnet : Petri_net.t ref)
                             pnetreacs
                             amolset
                             reacs_mgr =
    (* the new pnet is grabed *)
    let is_graber = Petri_net.can_grab new_mol amolset.dummy_pnet
    and is_grabed = Petri_net.can_grab amolset.dummy_pnet.mol !new_pnet
    in
    
    let new_d = { mol = new_mol;
                  pnet = new_pnet;
                  reacs = pnetreacs; }
    in
    if (is_graber || is_grabed)
    then 
      PnetSet.iter
        (fun (pnet, reacs) ->
          let current_d = { mol = amolset.dummy_pnet.mol;
                           pnet = pnet;
                           reacs = reacs;}
          in
          if is_graber
          then
            let new_agrab =
              Reacs_mgr.add_agrab new_d current_d reacs_mgr in
            reacs := Set.add new_agrab !reacs;
            pnetreacs := Set.add new_agrab !pnetreacs;
            
          if is_grabed
          then 
            let new_agrab =
              Reacs_mgr.add_agrab current_d new_d reacs_mgr in
            reacs := Set.add new_agrab !reacs;
            pnetreacs := Set.add new_agrab !pnetreacs;
        ) amolset.pnets;
    
end
                       
type t =
  {mutable inert_molecules : (int ref * (Reacs_mgr.reaction Set.t ref)) MolMap.t;
   mutable active_molecules : (int ref * ActiveMolSet.t) MolMap.t;
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
  
  if (MolMap.mem new_mol bact.inert_molecules
      || MolMap.mem new_mol bact.active_molecules)
  then 
    failwith "container : add_new_molecule : molecule was already present"
  else
    let new_opnet = Petri_net.make_from_mol new_mol
    in
    match new_opnet with
    | None ->
       let new_qtt = ref 1
       and new_reacs = ref Set.empty in
       
       MolMap.iter
         (fun mol (qtt, amolset) ->
           ActiveMolSet.add_reacs_with_new_mol
             new_mol new_qtt new_reacs amolset bact.reacs_mgr)
         bact.active_molecules;
       
       bact.inert_molecules <-
         MolMap.add new_mol
                    ( new_qtt, new_reacs) bact.inert_molecules;
       
    | Some new_pnet ->
       let new_rpnet = ref new_pnet
       and new_reacs = ref Set.empty in
       MolMap.iter
         (fun mol (qtt, amolset) ->
           ActiveMolSet.add_reacs_with_new_pnet
             new_mol new_rpnet new_reacs amolset bact.reacs_mgr)
         bact.active_molecules;

       let graber_d = {mol = new_mol;
                       pnet = new_rpnet;
                       reacs = new_reacs}
       in
       MolMap.iter
         (fun mol (qtt, molreacs) ->
           if Petri_net.can_grab mol new_pnet
           then
             let grabed_d = {mol = mol; qtt = qtt; reacs = new_reacs;}
             in
             let new_grab = 
               Reacs_mgr.add_grab graber_d grabed_d bact.reacs_mgr
             in
             new_reacs := Set.add new_grab !new_reacs;
             molreacs := Set.add new_grab !molreacs;
         ) bact.inert_molecules
       
(* *** update reaction rates *)

(* Update the rates of all the reactions implicating *)
(* a molecule                      *)

let update_rates reactions bact =
  Set.iter
    (fun reac ->
      Reacs_mgr.update_reaction_rates reac bact.reacs_mgr)
    reactions

  
(* *** set mol quantity *)
(* changes the number of items of a particular molecule *)
let set_inert_mol_quantity (mol : Molecule.t) (n : int) (bact : t) =
  if MolMap.mem mol bact.inert_molecules
  then
    let y, reacs = MolMap.find mol bact.inert_molecules in
    let old_quantity = !y in
    y := n;
    update_rates !reacs bact
  else
    failwith ("bacterie.ml : update_mol_quantity :  target molecule is not present\n"  ^mol)

let add_inert_mol_quantity (mol : Molecule.t) (n : int) (bact : t) : unit= 
  if MolMap.mem mol bact.inert_molecules
  then
    (
      let y, reacs= MolMap.find mol bact.inert_molecules in
      y := !y + n;
      update_rates !reacs bact
    )
  else
    failwith ("bacterie.ml : add_mol_quantity :  target molecule is not present\n"
              ^mol)
  
(* *** remove molecule *)
(* totally removes a molecule from a bactery *)
(* TODO : update reactives *)

let remove_molecule (m : Molecule.t) (bact : t) : unit =
  let old_quantity = ref 0
  and old_reacs = ref ([])
  in
  bact.molecules <-
    MolMap.modify_opt
      m
      (fun data ->
        match data with
        | None -> failwith "container: cannot remove absent molecule"
        | Some (n, _, reacs) ->
           old_quantity := !n;
           old_reacs := reacs;
           None)
      bact.molecules;
  bact.total_mol_count <-
    bact.total_mol_count - !old_quantity;
  update_rates !old_reacs bact

(* *** add_molecule *)
(* adds a molecule inside a bactery *)
(* on peut sûrement améliorer le bouzin, mais pour l'instant on se prends pas la tête *)
let add_molecule (mol : Molecule.t) (bact : t) : unit =
  
  if MolMap.mem mol bact.molecules
  then 
    add_mol_quantity mol 1 bact
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

let rec execute_actions (actions : Reacs_mgr.reaction_effect list) (bact : t) : unit =
  List.iter
    (fun effect ->
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
      | Update mol ->
         let _, _, reacs= MolMap.find mol bact.molecules in
         update_rates reacs bact)
  actions
                                     
    
let next_reaction (bact : t)  =
  let r = Reacs_mgr.pick_next_reaction bact.reacs_mgr in
  
  
  let actions = Reacs_mgr.treat_reaction r in
  execute_actions actions bact


(* ** json serialisation *)
type bact_elem = {nb : int;mol: Molecule.t} 
                   [@@ deriving yojson]
type bact_sig = bact_elem list
                          [@@ deriving yojson]
              
              
let to_json (bact : t) : Yojson.Safe.json =
  let mol_enum = MolMap.enum bact.molecules in
  let trimmed_mol_enum = Enum.map (fun (a,(b,c,_)) -> {mol=a; nb= !b}) mol_enum in
  let trimmed_mol_list = List.of_enum trimmed_mol_enum in
  bact_sig_to_yojson trimmed_mol_list
  
  
let json_reset (json : Yojson.Safe.json) (bact:t): unit  =
  match  bact_sig_of_yojson json with
  |Ok bact_sig -> 
    bact.molecules <- MolMap.empty;
    List.iter
      (fun {mol = m;nb = n} ->
        add_molecule m bact;
        set_mol_quantity m n bact;
        print_endline ("added mol: "^m);
      ) bact_sig;
  | Error s -> failwith s
