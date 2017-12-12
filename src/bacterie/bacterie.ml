(* * this file *)

(* on simule une bacterie entière - YAY *)

(* Alors comment on fait ??? *)

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
(*   Table d'association où les clés sont des molécule  Permet de stoquer efficacement la protéine associée *)
(*   et le nombre de molécules présentes. *)

(* * Bacterie module *)


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

(*    si on veut pouvoir simplifier avec les molécules qui n'ont  *)
(*    pas de pnet, il faudra avoir deux sets de reactives :  *)
(*    + un comme précédemment (donc seulement les mol' < mol) *)
(*      pour les molécules qui ont un PNet *)
(*    + un second qui ne contient que des molécules qui  *)
(*      n'ont pas de PNet *)


(* - il faudrait aussi stoquer séparement les molécules qui n'ont *)
(*   pas de réseau de pétri (ou des réseaux dégénérés) *)



(* ** types *)

              
module MolMap = Map.Make (struct type t = Molecule.t
                                 let compare = Pervasives.compare
                          end)

                    
module MolSet = Set.Make (struct type t = Molecule.t
                                 let compare = Pervasives.compare
                          end)
type t =
  {mutable molecules : (int * Petri_net.t option * MolSet.t) MolMap.t;}

(* an empty bactery *)
let make_empty () : t = 
  {molecules =  MolMap.empty;}
  
(* ** Molecules handling *)
(* Les fonctions suivantes servent à gérer les molécules (quantité) *)
(* à l'intérieur d'une bactérie *)

(* *** get_pnet_from_mol *)

let get_pnet_from_mol mol bact = 
  let (_,pnet, _) = MolMap.find mol bact.molecules in
  pnet

let get_mol_quantity mol bact = 
  let (n,_, _) = MolMap.find mol bact.molecules in
  n
  
(* *** add_molecule *)
(* adds a molecule inside a bactery *)
(* on peut sûrement améliorer le bouzin, mais pour l'instant on se prends pas la tête *)
let add_molecule (mol : Molecule.t) (bact : t) : unit =

  
  if MolMap.mem mol bact.molecules
  then 
    bact.molecules <- MolMap.modify mol (fun x -> let y,z,r = x in (y+1,z,r)) bact.molecules
  else
    let opnet = Petri_net.make_from_mol mol in
    
    let reactives = ref MolSet.empty in
    bact.molecules <-
      MolMap.mapi
        (fun mol' (n', opnet', reactives') ->
          if Petri_net.can_react mol opnet mol' opnet'
          then
            if mol' <= mol
            then
              (
                reactives := MolSet.add mol' !reactives;
                (n', opnet', reactives')
              )
            else
              (n', opnet', MolSet.add mol reactives')
          else
            (n', opnet', reactives')
        )
        bact.molecules;
    if Petri_net.can_react mol opnet mol opnet
    then reactives := MolSet.add mol !reactives;
    
    bact.molecules <-
      MolMap.add mol (1,opnet, !reactives) bact.molecules
       
       
                  

             
(* *** remove_molecule *)
(* totally removes a molecule from a bactery *)
let remove_molecule (m : Molecule.t) (bact : t) : unit =
  bact.molecules <- MolMap.remove m bact.molecules

(* *** add_to_mol_quantity *)
(* changes the number of items of a particular molecule *)
let add_to_mol_quantity (mol : Molecule.t) (n : int) (bact : t) =
  
  if MolMap.mem mol bact.molecules
  then 
    bact.molecules <- MolMap.modify mol (fun x -> let y,z,r = x in (y+n,z,r)) bact.molecules
  else
    failwith "cannot update absent molecule"
  
(* *** set_mol_quantity *)
(* changes the number of items of a particular molecule *)
let set_mol_quantity (mol : Molecule.t) (n : int) (bact : t) =
  if MolMap.mem mol bact.molecules
  then 
    bact.molecules <-
      MolMap.modify mol (fun x -> let y,z,r = x in (n,z,r)) bact.molecules
  else
    failwith ("bacterie.ml : cannot change quantity :  target molecule is not present\n"
              ^mol)

  
(* *** add_proteine *)
(* adds the molecule corresponding to a proteine to a bactery first transforms it back to a molecule, so the *)
(* process is not very natural. *)
(* **** SHOULD NOT BE USED *)

let add_proteine (prot : Proteine.t) (bact : t) : unit =
  let mol = Molecule.of_proteine prot in
  add_molecule mol bact



(* ** simulation ; new *)

(* *** interactions *)

  
(* ** Interactions  ; soon deprecated *)


(* *** asymetric_grab *)
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

(* *** try grabs *)
(* Resolve grabs when two molecules interact. Only one of the two *)
(* molecules will get to grab the other one, randomly decided. *)
(* We could also decide that if a mol can't grab, *)
(* then the other will try *)

let try_grabs (mol1 : Molecule.t) (mol2 : Molecule.t) (bact : t)
    : unit =
  let _,opnet1 = MolMap.find mol1 bact.molecules
  and _,opnet2 = MolMap.find mol2 bact.molecules
  and try_grab mol pnet =
    if asymetric_grab mol pnet
    then
      (
        add_to_mol_quantity mol (-1) bact;
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
  
let make_reactions (bact : t) =
  Enum.iter
    (fun mol1 ->
      Enum.iter
        (fun mol2 -> try_grabs mol1 mol2 bact)
        (MolMap.keys bact.molecules))
    (MolMap.keys bact.molecules)
  
  
  
(* ** simulation ; soon deprecated *)
(* *** execute_actions *)
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
        

(* *** launch_transition a specific transition in a specific pnet *)
let launch_transition tid mol bact : unit =
  match (MolMap.find mol bact.molecules) with
  | _, Some pnet ->
     let actions = Petri_net.launch_transition_by_id tid pnet in
     Petri_net.update_launchables pnet;
     execute_actions actions bact
  | _ -> ()
(* *** step_simulate *)
(* the more the quantity of a molecule, the more actions it *)
(* can do in one round *)
let step_simulate (bact : t) : unit = 
  MolMap.iter
    (fun k x ->
      match x with
      | (n, Some pnet) ->  
         for i = 1 to n do
           let actions = Petri_net.launch_random_transition pnet in
           Petri_net.update_launchables pnet;
           execute_actions actions bact
         done
      | n, None -> ())
    bact.molecules;
  make_reactions bact
  
(*    pop_all_messages bact *)

(* ** json serialisation *)
type bact_elem = {nb : int;mol: Molecule.t} 
                   [@@ deriving yojson]
type bact_sig = bact_elem list
                          [@@ deriving yojson]
              
              
let to_json (bact : t) : Yojson.Safe.json =
  let mol_enum = MolMap.enum bact.molecules in
  let trimmed_mol_enum = Enum.map (fun (a,(b,c)) -> {mol=a; nb=b}) mol_enum in
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
