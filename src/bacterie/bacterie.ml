

(* on simule une bacterie entière - YAY 
Alors comment on fait ???

   - on compte combien de molécules identiques de chaque type on a 
   ( ça voudrait dire qu'il faudrait bien les ranger
   pour vite les retrouver. Mais tout ça c'est pour plus tard)

   - on crée une protéine par type de molécule, la vitesse de simulation
   dépend du nombre de molécules (parce que à la fois c'est plus simple 
   et ça va plus vite, donc on se prive pas)
   
   - mais bon ya aussi des molécules qui sont associées à des token
   (donc faut se souvenir desquelles le sont), et puis aussi créer de
   nouvelles molécules quand elles apparaissent.

   - Il faudrait aussi tester rapidement si une molécule a une forme
   protéinée qui fait quelque chose, pour pas s'embêter avec


   - Et puis finalement la division, yavait plusieurs idées : 
     - au moment où les conditions sont réunies 
	- on crée automatiquement une nouvelle cellule
	- on a une action spécifique qui crée une nouvelle cellule
     - On peut soit créer la nouvelle cellule à l'exterieur, soit
     À L'INTERIEUR PETE SA MERE, du coup faut faire gaffe à pas en 
     rajouter trop, mais ça peut donner des choses rigolotes.



   - Il faut aussi implémenter un système de messages,
   c'est à dire référencer quelles molécules  reçoivent quel message


   - Et aussi savoir quelles molécules peuvent s'accrocher à quelles autres.
   
*)

open Moltypes.MyMolecule
open Maps
open Proteine

(* Table d'association où les clés sont des molécules.
   Permet de stoquer efficacement la protéine associée 
   et le nombre de molécules présentes. *)
module MolMap = MakeMolMap
  (struct type t = molecule let compare = Pervasives.compare end)


(* Table d'association où les clés sont des chaînes, 
   et les valeurs un doublet d'ensembles de molécules.
   Une chaîne représente l'identifiant d'un site d'accroche,
   la valeur associée contient à gauche les protéines qui sont attrapables,
   et à droite celles susceptibles de s'accrocher. *)
module MolDoubleMap = MakeDoubleMultiMap
  (struct type t = string let compare = String.compare end)
  (struct type t = molecule let compare = Pervasives.compare end)



  
module Bacterie =
struct
  type t =
    {mutable molecules : (int * Proteine.t) MolMap.t;
     mutable message_receptors_map :
       (string, molecule) BatMultiPMap.t;
     mutable mol_bindings_map :
       MolDoubleMap.set_pair MolDoubleMap.t;
     mutable message_queue : string list;}


  let empty : t = 
    {molecules =  MolMap.empty;
     message_receptors_map = BatMultiPMap.create compare compare;
     mol_bindings_map = MolDoubleMap.empty;
     message_queue = [];}

    
  let launch_message (m : string) (bact : t) : unit = 
    BatSet.PSet.iter 
      (fun x -> 
	let _,p = MolMap.find x bact.molecules in
	Proteine.send_message m p)
      (BatMultiPMap.find m bact.message_receptors_map)
    
  let pop_all_messages (bact:t) : unit = 
    List.iter (fun x -> launch_message x bact) bact.message_queue;
    bact.message_queue <- []


  let add_molecule (m : molecule) (bact : t) : unit =
    
    let update_map 
	(mol : molecule)
	(molMap : (string, int) BatMultiPMap.t)
	(map : (string, molecule) BatMultiPMap.t) 
	
	:  (string, molecule) BatMultiPMap.t
	= 
      BatMultiPMap.foldi 
	(fun k v m -> BatMultiPMap.add k mol m)
	molMap 
	map
	
    and update_bindings_map
	(mol : molecule)
	(leftMap : (string, int) BatMultiPMap.t)
	(rightMap :  (string, int) BatMultiPMap.t)
	(map : MolDoubleMap.set_pair MolDoubleMap.t)
	: MolDoubleMap.set_pair MolDoubleMap.t
	= 
      BatMultiPMap.foldi
	(fun k v m -> MolDoubleMap.add_left k mol m)
	leftMap
	(BatMultiPMap.foldi
	   (fun k v m -> MolDoubleMap.add_right k mol m)
	   rightMap
	   map)	
    in
    if MolMap.mem m bact.molecules
    then 
      bact.molecules <- MolMap.modify m (fun x -> let y,z = x in (y+1,z)) bact.molecules
    else
      let p = Proteine.make m in
      bact.message_receptors_map <- update_map m p.Proteine.message_receptors_book bact.message_receptors_map;
      bact.mol_bindings_map <- update_bindings_map m p.Proteine.handles_book p.Proteine.mol_catchers_book bact.mol_bindings_map;
      bact.molecules <- MolMap.add m (1,p) bact.molecules


  (* il faudrait peut-être mettre dans une file les molécules à ajouter *)
  let rec execute_actions (actions : return_action list) (bact : t) : unit =
    match actions with
    | AddMol mh :: actions' ->
       add_molecule (MoleculeHolder.get_molecule mh) bact;
      execute_actions actions' bact
    | SendMessage m :: actions' ->
       bact.message_queue <- m :: bact.message_queue;
      execute_actions actions' bact
    | NoAction :: actions' -> execute_actions actions' bact
    | [] -> ()

       let bind_to 
    (boundMol : molecule) 
    (hostMol : molecule) 
    (bindPattern : string)
    (bact : t)
    : unit = 
    
    let (_,p) = MolMap.find hostMol bact.molecules
    in 
    let reac_result = Proteine.bind_mol boundMol bindPattern p
    in
    if reac_result
    then 
      bact.molecules <- MolMap.rel_change_mol_quantity boundMol (-1) bact.molecules
    else
      ()
      
  let make_bindings (bact : t) : unit = 
    MolDoubleMap.iter
      (fun 
	(pattern : string) 
	(mols : MolDoubleMap.set_pair) -> 
	let handles, catchers = mols in 
	let handles_l = MolDoubleMap.Set.to_list handles and catchers_l = MolDoubleMap.Set.to_list catchers in
	let couples_list = Misc_library.get_all_couples handles_l catchers_l
	in 
	List.iter 
	  (fun x -> 
	    let (handle, catcher) = x in
	    let handle_num, _ = MolMap.find handle bact.molecules 
	    and catcher_num, _ = MolMap.find catcher bact.molecules
	    in
	    if Reactions.react handle_num catcher_num
	    then bind_to handle catcher pattern bact
	  )
	  couples_list)
      bact.mol_bindings_map;
    ()


	
  let step_simulate (bact : t) : unit = 
    MolMap.iter
      (fun k x -> let (n, prot) = x in  
		  for i = 1 to n do
		    let actions = Proteine.launch_random_transition prot in
		    execute_actions actions bact
		  done)
      bact.molecules;
    make_bindings bact;
    pop_all_messages bact
      
  
  
end;;
