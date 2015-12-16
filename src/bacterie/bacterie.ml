

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
  
  let updateMap 
    (mol : molecule)
    (molMap : (string, int) BatMultiPMap.t)
    (map : (string, molecule) BatMultiPMap.t) 
    
    :  (string, molecule) BatMultiPMap.t
    = 
    BatMultiPMap.foldi 
      (fun k v m -> BatMultiPMap.add k mol m)
      molMap 
      map
  
  and updateBindingsMap
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
  
  val mutable messageReceptorsMap : 
      (string, molecule) BatMultiPMap.t = 
    BatMultiPMap.create String.compare Pervasives.compare
    
  val mutable molBindingsMap :
      MolDoubleMap.set_pair MolDoubleMap.t
      = MolDoubleMap.empty

  val mutable messageQueue = []

  method sendMessage (s : string) : unit = 
    messageQueue <- s :: messageQueue
      
  method popMessage : unit = 
    let h::t = messageQueue in
    messageQueue <- t;
    BatSet.PSet.map 
      (fun x -> 
	let _,p = MolMap.find x molecules in
	p#sendMessage h)
      (BatMultiPMap.find h messageReceptorsMap);
    ()


  method add_molecule (m : molecule) : unit = 
    if MolMap.mem m molecules
    then 
      molecules <- MolMap.modify m (fun x -> let y,z = x in (y+1,z)) molecules
    else
      let p = new Proteine.proteine m in
      p#setHost (self :> Proteine.container);
      let messageMap, catchersMap, handlesMap = p#getMaps in
      messageReceptorsMap <- updateMap m messageMap messageReceptorsMap;
      molBindingsMap <- updateBindingsMap m handlesMap catchersMap molBindingsMap;
      molecules <- MolMap.add m (1,p) molecules;
      
    
    
  method stepSimulate : unit = 
    MolMap.map
      (fun x -> let (n, prot) = x in  
		for i = 1 to n do
		  prot#launchRandomTransition
		done)
      molecules;
    ()

  method bind_to 
    (hostMol : molecule) 
    (boundMol : molecule) 
    (bindPattern : string) 
    : unit = 
    
    let (_,p) = MolMap.find hostMol molecules
    in 
    p#bindMol boundMol bindPattern
    


end
