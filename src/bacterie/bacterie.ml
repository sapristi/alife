

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

open Types.MyMolecule
open Maps


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


(* Classe qui simule une bactérie, 
   c'est à dire organise la simulation des protéines. *)
class bacterie = 
  
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

object(self)
  val mutable molecules : (int * Proteine.proteine) MolMap.t = MolMap.empty
  
  val mutable message_receptors_map : 
      (string, molecule) BatMultiPMap.t = 
    BatMultiPMap.create String.compare Pervasives.compare
    
  val mutable mol_bindings_map :
      MolDoubleMap.set_pair MolDoubleMap.t
      = MolDoubleMap.empty

  val mutable message_queue = []

  method send_message (s : string) : unit = 
    message_queue <- s :: message_queue
      
  method launch_message (m : string) : unit = 
    BatSet.PSet.map 
      (fun x -> 
	let _,p = MolMap.find x molecules in
	p#send_message m)
      (BatMultiPMap.find m message_receptors_map);
    ()

  method pop_all_messages : unit = 
    List.map (fun x -> self#launch_message x) message_queue;
    message_queue <- []


  method add_molecule (m : molecule) : unit = 
    if MolMap.mem m molecules
    then 
      molecules <- MolMap.modify m (fun x -> let y,z = x in (y+1,z)) molecules
    else
      let p = new Proteine.proteine m in
      p#set_host (self :> Proteine.container);
      let messageMap, catchersMap, handlesMap = p#get_maps in
      message_receptors_map <- update_map m messageMap message_receptors_map;
      mol_bindings_map <- update_bindings_map m handlesMap catchersMap mol_bindings_map;
      molecules <- MolMap.add m (1,p) molecules;
      
    
    
  method step_simulate : unit = 
    MolMap.map
      (fun x -> let (n, prot) = x in  
		for i = 1 to n do
		  prot#launch_random_transition
		done)
      molecules;
    self#make_bindings;
    self#pop_all_messages


  method make_bindings : unit = 
    MolDoubleMap.mapi
      (fun 
	(pattern : string) 
	(mols : MolDoubleMap.set_pair) -> 
	let handles, catchers = mols in 
	let handles_l = MolDoubleMap.Set.to_list handles and catchers_l = MolDoubleMap.Set.to_list catchers in
	let couples_list = Misc_library.get_all_couples handles_l catchers_l
	in 
	List.map 
	  (fun x -> 
	    let (handle, catcher) = x in
	    let handle_num, _ = MolMap.find handle molecules 
	    and catcher_num, _ = MolMap.find catcher molecules
	    in
	    if Reactions.react handle_num catcher_num
	    then self#bind_to handle catcher pattern
	  )
	  couples_list)
      mol_bindings_map;
    ()
      
      
  method bind_to 
    (boundMol : molecule) 
    (hostMol : molecule) 
    (bindPattern : string) 
    : unit = 
    
    let (_,p) = MolMap.find hostMol molecules
    in 
    let reac_result = p#bind_mol boundMol bindPattern
    in
    if reac_result
    then 
      molecules <- MolMap.rel_change_mol_quantity boundMol (-1) molecules
    else
      ()


end
