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
open Reactions
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
  {mutable molecules : ((int ref * Petri_net.t option ref * MolSet.t) ) MolMap.t;
   mutable total_mol_count : int;}
  
  
(* ** interface *)

(* Whenever modifying the bactery, it should be *)
(* done through these functions alone *)

(* *** make empty *)
(* an empty bactery *)
let make_empty () : t = 
  {molecules =  MolMap.empty;
   total_mol_count = 0;}
(* *** add new molecule *)
(* adds a new molecule inside a bactery *)
(* on peut sûrement améliorer le bouzin, mais pour l'instant on se prends pas la tête *)
let add_new_molecule (mol : Molecule.t) (bact : t) : unit =

  
  if MolMap.mem mol bact.molecules
  then 
    failwith "container : add_new_molecule : molecule was already present"
  else
    let opnet = Petri_net.make_from_mol mol in
    
    let reactives = ref MolSet.empty in
    bact.molecules <-
      MolMap.mapi
        (fun mol' (rn', ropnet', reactives') ->
          if Petri_net.can_react mol opnet mol' (!ropnet')
          then
            if mol' <= mol
            then
              (
                reactives := MolSet.add mol' !reactives;
                (rn', ropnet', reactives')
              )
            else
              (rn', ropnet', MolSet.add mol reactives')
          else
            (rn', ropnet', reactives')
        )
        bact.molecules;
    if Petri_net.can_react mol opnet mol opnet
    then reactives := MolSet.add mol !reactives;
    
    bact.molecules <-
      MolMap.add mol (ref 1,ref opnet, !reactives) bact.molecules;
    bact.total_mol_count <-
      bact.total_mol_count + 1
       

  
(* *** set mol quantity *)
(* changes the number of items of a particular molecule *)
let set_mol_quantity (mol : Molecule.t) (n : int) (bact : t) =
  if MolMap.mem mol bact.molecules
  then
    let y, _, _ = MolMap.find mol bact.molecules in
    let old_quantity = !y in
    y := n;
    bact.total_mol_count <-
      bact.total_mol_count + n - old_quantity
  else
    failwith ("bacterie.ml : update_mol_quantity :  target molecule is not present\n"
              ^mol)

let add_mol_quantity (mol : Molecule.t) (n : int) (bact : t) : unit= 
  if MolMap.mem mol bact.molecules
  then
    (
      let y, _, _ = MolMap.find mol bact.molecules in
      y := !y + n;
      bact.total_mol_count <-
        bact.total_mol_count + n;
    )
  else
    failwith ("bacterie.ml : add_mol_quantity :  target molecule is not present\n"
              ^mol)
  
(* *** remove molecule *)
(* totally removes a molecule from a bactery *)
(* TODO : update reactives *)

let remove_molecule (m : Molecule.t) (bact : t) : unit =
  let old_quantity = ref 0 in
  bact.molecules <-
    MolMap.modify_opt
      m
      (fun data ->
        match data with
        | None -> failwith "container: cannot remove absent molecule"
        | Some (n, _, _) ->
           old_quantity := !n;
           None)
      bact.molecules;
  bact.total_mol_count <-
    bact.total_mol_count - !old_quantity

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

             
(* *** reactions *)

(* **** transitions *)

let transition_reactions (bact:t) : float*((float*reaction) list) =
  MolMap.fold
    (fun mol1 (n, opnet, _) res ->
      match opnet with
      | Some pnet ->
         let total_rate, l = res
         and rate = (float_of_int n) /. (float_of_int bact.total_mol_count) in
         (total_rate +. rate, (rate, Transition pnet) :: l)
      | None -> res
    )
    bact.molecules
    (0., [])
(* **** collision *)
(*     The collision probability between two molecules is *)
(*     the product of their quantities. *)
(*     We might need to add other parameters, such as *)
(*     the volume of the container, and use a float constant *)
(*     to avoid integer overflow. *)
(*     We here calculate each collision probability, *)
(*     and the sum of it. *)
(*     WARNING : possible integer overflow *)

let collision_reactions (bact : t) : float *((float* reaction) list) =
  MolMap.fold
    (fun mol1 (n1, _, react_set) res ->
      MolSet.fold
        (fun mol2 res' ->
          let (n2, _, _ ) = MolMap.find mol2 bact.molecules in
          let (total, l) = res' in
          let current_rate = (float_of_int (!n1*(!n2))) /. float_of_int bact.total_mol_count in
          (current_rate +. total,
           (current_rate, Collision (mol1, mol2))::l))
        react_set
        res)
    bact.molecules
    (0., [])


(* *** Interactions *)


(* **** asymetric_grab *)
(* auxilary function used by try_grabs *)
(* Try the grab of a molecule by a pnet *)

let asymetric_grab mol pnet = 
  let grabs = Petri_net.get_possible_mol_grabs mol pnet
  in
  if not (grabs = [])
  then
    let grab,pid = random_pick_from_list grabs in
    match grab with
    | pos -> Petri_net.grab mol pos pid pnet
  else
    false

(* **** try grabs *)
(* Resolve grabs when two molecules interact. Only one of the two *)
(* molecules will get to grab the other one, randomly decided. *)
(* We could also decide that if a mol can't grab, *)
(* then the other will try *)

let try_grabs (mol1 : Molecule.t) (mol2 : Molecule.t) (bact : t)
    : unit =
  let _,{contents = opnet1},_ = MolMap.find mol1 bact.molecules
  and _,{contents = opnet2}, _ = MolMap.find mol2 bact.molecules
  and try_grab mol pnet =
    if asymetric_grab mol pnet
    then
      (
        add_mol_quantity mol (-1) bact;
        Petri_net.update_launchables pnet
      )
    else ()
               
  in
  match opnet1, opnet2 with
  | Some pnet1, Some pnet2 ->
     if Random.bool ()
     then try_grab mol2 pnet1
     else try_grab mol1 pnet2
  | Some pnet1, None -> try_grab mol2 pnet1
  | None, Some pnet2 -> try_grab mol1 pnet2
  | None, None -> ()
                
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

let rec execute_actions (actions : Place.transition_effect list) (bact : t) : unit =
  match actions with
  | Place.Release_effect mol :: actions' ->
     if mol != ""
     then add_molecule mol bact;
     execute_actions actions' bact
  | Place.Message_effect m :: actions' ->
     (* bact.message_queue <- m :: bact.message_queue; *)
     execute_actions actions' bact
  | [] -> ()
        
  
let treat_reaction (bact : t) (r : reaction) =
  match r with
  | Transition pnet ->
     let actions = Petri_net.launch_random_transition pnet in
     Petri_net.update_launchables pnet;
     execute_actions actions bact
  | Collision (mol1,mol2) ->
     try_grabs mol1 mol2 bact
  | _ ->
     failwith "treat_reaction@bacterie.ml : can't treat meta reaction"

let next_reaction (bact : t)  =
  let t_rate, t_reacs = transition_reactions bact
  and col_rate, col_reacs = collision_reactions bact in
  print_endline (Reactions.show_reaction (Meta t_reacs));
  print_endline (Reactions.show_reaction (Meta col_reacs));
  let r =  pick_reaction (t_rate +. col_rate)
                         (Meta [(t_rate, Meta t_reacs);
                                (col_rate, Meta col_reacs)])
  in treat_reaction bact r   

  
  
(* ** simulation ; soon deprecated *)

        
(* *** launch_transition a specific transition in a specific pnet *)
let launch_transition tid mol bact : unit =
  match (MolMap.find mol bact.molecules) with
  | _, {contents = Some pnet}, _ ->
     let actions = Petri_net.launch_transition_by_id tid pnet in
     Petri_net.update_launchables pnet;
     execute_actions actions bact
  | _ -> ()

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
