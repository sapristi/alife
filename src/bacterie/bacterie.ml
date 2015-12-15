

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

module OrderedMolType = 
struct
  type t = molecule
  let compare = Pervasives.compare
end

module MolMap = BatMap.Make(OrderedMolType)

class bacterie = 
  
object(self)
  val molecules : (int * Proteine.proteine) MolMap.t = MolMap.empty
  
  val mutable messageReceptorsMap : 
      (string, molecule) BatMultiPMap.t = 
    BatMultiPMap.create String.compare Pervasives.compare
  
  val mutable molCatchersMap : 
      (string, molecule) BatMultiPMap.t = 
    BatMultiPMap.create String.compare Pervasives.compare
    
  val mutable molHandlesMap :
      (string, molecule) BatMultiPMap.t = 
    BatMultiPMap.create String.compare Pervasives.compare
    

  val mutable messageQueue = []

  method sendMessage (s : string) : unit = 
    messageQueue <- s :: messageQueue
      
      
  method add_molecule m = 
    if MolMap.mem m molecules
    then 
      MolMap.modify m (fun x -> let y,z = x in (y+1,z)) molecules
    else
      let p = new Proteine.proteine m in
      p#setHost (self :> Proteine.container);
      let messageMap, catchersMap, handlesMap = p#getMaps in
      messageReceptorsMap <- self#updateMap m messageMap messageReceptorsMap;
      molCatchersMap <- self#updateMap m catchersMap molCatchersMap;
      molHandlesMap <- self#updateMap m handlesMap molHandlesMap;
      MolMap.add m (1,p) molecules
	
  method updateMap 
    (mol : molecule)
    (molMap : (string, int) BatMultiPMap.t)
    (map : (string, molecule) BatMultiPMap.t) 
    
    :  (string, molecule) BatMultiPMap.t
    = 
    BatMultiPMap.foldi 
      (fun k v m -> BatMultiPMap.add k mol m)
      molMap 
      map

      
  method stepSimulate = 
    MolMap.map
      (fun x -> let (n, prot) = x in  
		for i = 1 to n do
		  prot#launchRandomTransition
		done)
      molecules

  method findBindings = 
    

end
