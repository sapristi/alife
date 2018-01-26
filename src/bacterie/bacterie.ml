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
open Reactions_new
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
              
type t =
  {mutable molecules : (int ref * Petri_net.t option ref * ((Reactions_new.reaction list))) MolMap.t;
   mutable total_mol_count : int;
   reacs : Reactions_new.t;
  }
  
  
(* ** interface *)
  
(* Whenever modifying the bactery, it should be *)
(* done through these functions alone *)

(* *** make empty *)
(* an empty bactery *)
let make_empty () : t = 
  {molecules =  MolMap.empty;
   total_mol_count = 0;
   reacs = Reactions_new.make_new ();}
(* *** add new molecule *)
(* adds a new molecule inside a bactery *)
(* on peut sûrement améliorer le bouzin, mais pour l'instant on se prends pas la tête *)
let add_new_molecule (mol : Molecule.t) (bact : t) : unit =
  
  if MolMap.mem mol bact.molecules
  then 
    failwith "container : add_new_molecule : molecule was already present"
  else
    let ropnet = ref (Petri_net.make_from_mol mol)
    and qtt = ref 1
    in
    
    let reactions = ref [] in
    bact.molecules <-
      MolMap.mapi
        (fun mol' (qtt', ropnet', reactions') ->
          let rreactions' = ref reactions' in
          if Petri_net.ocan_grab mol (!ropnet')
          then
            (
              let md1 = {mol = mol'; qtt = qtt'; pnet = ropnet'}
              and md2 = {mol; qtt; pnet = ropnet}
              in
              let new_grab =
                Reactions_new.add_grab md1 md2 bact.reacs
            in
            reactions := new_grab :: !reactions;
            rreactions' := new_grab:: !rreactions'
            );
          if Petri_net.ocan_grab mol' (!ropnet)
          then
            (
              let md2 = {mol = mol'; qtt = qtt'; pnet = ropnet'}
              and md1 = {mol = mol; qtt = qtt; pnet = ropnet}
              in
              let new_grab =
                Reactions_new.add_grab md1 md2 bact.reacs
            in
            reactions :=  new_grab :: !reactions;
            rreactions' := new_grab:: !rreactions'
            );
            (qtt', ropnet', !rreactions')
        )
        bact.molecules;
    if Petri_net.can_react mol !ropnet mol !ropnet
    then
      (
        let md = {mol; qtt; pnet =ropnet} in
        let new_self_grab = Reactions_new.add_self_grab
                              md
                              bact.reacs
        in
        reactions := new_self_grab :: (!reactions);
      );
    (
      match !ropnet with  
      | Some pnet ->
        let trans = Reactions_new.add_transition {mol; qtt; pnet=ropnet} bact.reacs
        in reactions := trans:: !reactions
      | None -> ()
    );       
    bact.molecules <-
      MolMap.add mol (qtt,ropnet, !reactions) bact.molecules;
    bact.total_mol_count <-
      bact.total_mol_count + 1
       
(* *** update reaction rates *)

(* Update the rates of all the reactions implicating *)
(* a molecule                      *)

let update_rates reactions bact =
  List.iter
    (fun reac ->
      Reactions_new.update_reaction_rates reac bact.reacs)
    reactions

  
(* *** set mol quantity *)
(* changes the number of items of a particular molecule *)
let set_mol_quantity (mol : Molecule.t) (n : int) (bact : t) =
  if MolMap.mem mol bact.molecules
  then
    let y, _,reacs = MolMap.find mol bact.molecules in
    let old_quantity = !y in
    y := n;
    bact.total_mol_count <-
      bact.total_mol_count + n - old_quantity;
    update_rates reacs bact
  else
    failwith ("bacterie.ml : update_mol_quantity :  target molecule is not present\n"
              ^mol)

let add_mol_quantity (mol : Molecule.t) (n : int) (bact : t) : unit= 
  if MolMap.mem mol bact.molecules
  then
    (
      let y, _, reacs= MolMap.find mol bact.molecules in
      y := !y + n;
      bact.total_mol_count <-
        bact.total_mol_count + n;
      update_rates reacs bact
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

let rec execute_actions (actions : Reactions_new.reaction_effect list) (bact : t) : unit =
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
  let r = Reactions_new.pick_next_reaction bact.reacs in
  
  Logs.info (fun m -> m "picked reaction %s" (Reactions_new.show_reaction r));
  
  let actions = Reactions_new.treat_reaction r in
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
