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
open Molecule
open Transition
open Proteine
open Misc_library
open Maps
open Petri_net
open Batteries
open Graber
open Place
   
(*   Table d'association où les clés sont des molécule  Permet de stoquer efficacement la protéine associée *)
(*   et le nombre de molécules présentes. *)

module MolMap = MakeMolMap
  (struct type t = Molecule.t let compare = Pervasives.compare end)

(* * Bacterie module *)

(* Une bacterie est un conteneur à molecules. Elle s'occupe de fournir l'interprétation d'une molécule en tant que *)
(* protéine (i.e. pnet), puis d'organiser la simulation des pnet *)
(* et de leurs interactions. *)
module Bacterie =
struct
  type t =
    {mutable molecules : (int * PetriNet.t) MolMap.t}

  (* an empty bactery *)
  let make_empty () : t = 
    {molecules =  MolMap.empty;}
    
(* ** Molecules handling *)
(* Les fonctions suivantes servent à gérer les molécules (quantité) *)
(* à l'intérieur d'une bactérie *)

(* *** get_pnet_from_mol *)

  let get_pnet_from_mol mol bact = 
    let (_,pnet) = MolMap.find mol bact.molecules in
    pnet

    
(* *** add_molecule *)
(* adds a molecule inside a bactery *)
  let add_molecule (m : Molecule.t) (bact : t) : unit =
    
    if MolMap.mem m bact.molecules
    then 
      bact.molecules <- MolMap.modify m (fun x -> let y,z = x in (y+1,z)) bact.molecules
    else
      let p = PetriNet.make_from_mol m in
      bact.molecules <- MolMap.add m (1,p) bact.molecules
      
(* *** remove_molecule *)
(* totally removes a molecule from a bactery *)
  let remove_molecule (m : Molecule.t) (bact : t) : unit =
    bact.molecules <- MolMap.remove m bact.molecules

(* *** add_to_mol_quantity *)
(* changes the number of items of a particular molecule *)
  let add_to_mol_quantity (mol : Molecule.t) (n : int) (bact : t) =
    
    if MolMap.mem mol bact.molecules
    then 
      bact.molecules <- MolMap.modify mol (fun x -> let y,z = x in (y+n,z)) bact.molecules
    else
      failwith "cannot update absent molecule"
    
(* *** set_mol_quantity *)
(* changes the number of items of a particular molecule *)
  let set_mol_quantity (mol : Molecule.t) (n : int) (bact : t) =
    if MolMap.mem mol bact.molecules
    then 
      bact.molecules <- MolMap.modify mol (fun x -> let y,z = x in (n,z)) bact.molecules
    else
      failwith "bacterie.ml : cannot change quantity :  target molecule is not present"

  
(* *** add_proteine *)
(* adds the molecule corresponding to a proteine to a bactery 
     first transforms it back to a molecule, so the 
     process is not very natural.
     **** SHOULD NOT BE USED
     *)
  let add_proteine (prot : Proteine.t) (bact : t) : unit =
    let mol = Molecule.of_proteine prot in
    add_molecule mol bact
    

(* ** Interactions *)  


(* *** asymetric_grab *)
(* auxilary function used by try_grabs *)
(* Try the grab of a molecule by a pnet *)

  let asymetric_grab mol pnet = 
    let grabs = PetriNet.get_possible_mol_grabs mol pnet
    in
    if not (grabs = [])
    then
      let grab,pid = random_pick_from_list grabs in
      match grab with
      | pos -> PetriNet.grab mol pos pid pnet
    else
      false

(* *** try grabs *)
(* Resolve grabs when two molecules interact. Only one of the two *)
(* molecules will get to grab the other one, randomly decided. *)
(* We could also decide that if a mol can't grab, *)
(* then the other will try *)

  let try_grabs (mol1 : Molecule.t) (mol2 : Molecule.t) (bact : t)
      : unit =
    let _,pnet1 = MolMap.find mol1 bact.molecules
    and _,pnet2 = MolMap.find mol2 bact.molecules in
    if Random.bool ()
    then
      (
        if asymetric_grab mol2 pnet1
        then
          (
            add_to_mol_quantity mol2 (-1) bact;
            PetriNet.update_launchables pnet1
          )
        else ()
      )
    else
      (
        if  asymetric_grab mol1 pnet2
        then
          (
            add_to_mol_quantity mol1 (-1) bact;
            PetriNet.update_launchables pnet2
          )
        else ()
      )
    
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
    

(* ** simulation *) 
(* *** execute_actions *)
(* after a transition from a proteine has occured,   *)
(*    some actions may need to be performed by the bactery  *)
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
            

(* *** launch_transition a specific transition in a specific pnet*)
  let launch_transition tid mol bact : unit =
    let _,pnet = MolMap.find mol bact.molecules in
    let actions = PetriNet.launch_transition_by_id tid pnet in
    PetriNet.update_launchables pnet;
    execute_actions actions bact

(* *** step_simulate *)
(* the more the quantity of a molecule, the more actions it can
do in one round *)    
  let step_simulate (bact : t) : unit = 
    MolMap.iter
      (fun k x ->
        let (n, pnet) = x in  
        for i = 1 to n do
          let actions = PetriNet.launch_random_transition pnet in
          PetriNet.update_launchables pnet;
          execute_actions actions bact
        done)
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
          set_mol_quantity m n bact;) bact_sig;
    | Error s -> failwith s
                     
end;;
