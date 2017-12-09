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

module MolMap = MakeMolMap
                  (struct type t = Molecule.t
                          let compare = Pervasives.compare
                   end)

(* * Bacterie module *)

(* Une bacterie est un conteneur à molecules. Elle s'occupe de fournir l'interprétation d'une molécule en tant que *)
(* protéine (i.e. pnet), puis d'organiser la simulation des pnet *)
(* et de leurs interactions. *)

(* grabers_map : associe à chaque graber  *)
(*   - l'ensemble des places qui contiennet ce graber *)
(*   - l'ensemble des molécules qui peuvent être attrapées par *)
(*     ce graber *)

module PSet = Set.Make (struct type t = (Molecule.t*int)
                               let compare = Pervasives.compare
                        end)
module MolSet = Set.Make (struct type t = Molecule.t
                                 let compare = Pervasives.compare
                          end)
module GMap = Map.Make (struct type t = Graber.t
                               let compare g1 g2 =
                                 Pervasives.compare g1.Graber.mol_repr
                                                    g2.Graber.mol_repr
                        end)
type gmap = (PSet.t * MolSet.t) GMap.t
module BMap = Map.Make (struct type t = string
                               let compare = Pervasives.compare 
                        end)
type bmap = (PSet.t * PSet.t) BMap.t
          
type t =
  {mutable molecules : (int * Petri_net.t option) MolMap.t;
   mutable grabers_map : (PSet.t * MolSet.t)  GMap.t;
   mutable binders_map : (PSet.t * PSet.t) BMap.t;
                         }

(* an empty bactery *)
let make_empty () : t = 
  {molecules =  MolMap.empty;
   grabers_map = GMap.empty;
   binders_map = BMap.empty}
  
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
  
  let add_graber (g : Graber.t)
                 (mol : Molecule.t)
                 (pid : int)
                 (bact : t) : unit =
    try
      bact.grabers_map <-
        GMap.modify g 
        (fun (pset, molset) -> (PSet.add (mol, pid) pset, molset))
        bact.grabers_map
    with Not_found ->
         let grabable_mols =
           Enum.fold
             (fun res mol ->
               match Graber.get_match_pos g mol with
               | None -> res
               | Some _ -> MolSet.add mol res
             ) MolSet.empty (MolMap.keys bact.molecules)
           in
      bact.grabers_map <-
        GMap.add g ((PSet.singleton (mol,pid)), grabable_mols)
        bact.grabers_map
  in

  let add_binder (b:string)
                 (mol : Molecule.t)
                 (pid : int)
                 (bact : t) : unit =

    let b' = String.rev b in
    if b < b'
    then
      bact.binders_map <-
        BMap.modify_def (PSet.singleton (mol, pid), PSet.empty)
                        b
                        (fun (l, r) ->
                          (PSet.add (mol, pid) l, r))
                        bact.binders_map
    else if b > b'
    then
      bact.binders_map <-
        BMap.modify_def (PSet.empty, PSet.singleton (mol, pid))
                        b'
                        (fun (l, r) ->
                          (l, PSet.add (mol, pid) r))
                        bact.binders_map
    else 
      bact.binders_map <-
        BMap.modify_def (PSet.singleton (mol, pid),
                         PSet.singleton (mol, pid))
                        b
                        (fun (l, r) ->
                          (PSet.add (mol, pid)l,
                           PSet.add (mol, pid) r))
                        bact.binders_map
  in
  
  if MolMap.mem m bact.molecules
  then 
    bact.molecules <- MolMap.modify m (fun x -> let y,z = x in (y+1,z)) bact.molecules
  else
    let p = Petri_net.make_from_mol m in
    bact.molecules <- MolMap.add m (1,p) bact.molecules;
    match p with
    | None -> ()
    | Some pnet ->
       Array.iteri
         (fun i place ->
           (
             match place.Place.graber with
             | None -> ()
             | Some g -> add_graber g m i bact
           );
           match place.Place.binder with
           | None -> ()
           | Some b -> add_binder b m i bact
         ) pnet.places
                    
                
                  
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
    failwith ("bacterie.ml : cannot change quantity :  target molecule is not present\n"
              ^mol)

  
(* *** add_proteine *)
(* adds the molecule corresponding to a proteine to a bactery first transforms it back to a molecule, so the  *)
(* process is not very natural. *)
(* **** SHOULD NOT BE USED *)

let add_proteine (prot : Proteine.t) (bact : t) : unit =
  let mol = Molecule.of_proteine prot in
  add_molecule mol bact

(* ** Interactions   *)


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
  

(* ** simulation  *)
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
(* the more the quantity of a molecule, the more actions it  *)
(* can do in one round     *)
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
