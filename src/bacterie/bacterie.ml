(* * this file *)

(* on simule une bacterie entière - YAY *)

(* Alors comment on fait ??? *)

(*   - on compte combien de molécules identiques de chaque type on a *)
(*    ( ça voudrait dire qu'il faudrait bien les ranger *)
(*    pour vite les retrouver. Mais tout ça c'est pour plus tard) *)

(*   - on crée une protéine par type de molécule, la vitesse de simulation *)
(*    dépend du nombre de molécules (parce que à la fois c'est plus simple *)
(*    et ça va plus vite, donc on se prive pas) *)
   
(*   - mais bon ya aussi des molécules qui sont associées à des token *)
(*    (donc faut se souvenir desquelles le sont), et puis aussi créer de *)
(*    nouvelles molécules quand elles apparaissent. *)

(*   - Il faudrait aussi tester rapidement si une molécule a une forme *)
(*    protéinée qui fait quelque chose, pour pas s'embêter avec *)

(*   - Et puis finalement la division, yavait plusieurs idées : *)
(*      + au moment où les conditions sont réunies *)
(* 	* on crée automatiquement une nouvelle cellule *)
(* 	* on a une action spécifique qui crée une nouvelle cellule *)
(*      + On peut soit créer la nouvelle cellule à l'exterieur, soit *)
(*      À L'INTERIEUR PETE SA MERE, du coup faut faire gaffe à pas en *)
(*      rajouter trop, mais ça peut donner des choses rigolotes. *)

(*   - Il faut aussi implémenter un système de messages, *)
(*    c'est à dire référencer quelles molécules  reçoivent quel message *)

(*   - Et aussi savoir quelles molécules peuvent s'accrocher à quelles autres. *)

(* * libs *)
open Molecule
open Transition
open Proteine

open Misc_library
open Maps
open Petri_net
   
open Batteries

   
(*   Table d'association où les clés sont des molécule  Permet de stoquer efficacement la protéine associée *)
(*   et le nombre de molécules présentes. *)

module MolMap = MakeMolMap
  (struct type t = Molecule.t let compare = Pervasives.compare end)


  
module Bacterie =
struct
  type t =
    {mutable molecules : (int * PetriNet.t) MolMap.t}
    

  let empty : t = 
    {molecules =  MolMap.empty;}
    
  let add_molecule (m : Molecule.t) (bact : t) : unit =
        
    if MolMap.mem m bact.molecules
    then 
      bact.molecules <- MolMap.modify m (fun x -> let y,z = x in (y+1,z)) bact.molecules
    else
      let p = PetriNet.make m in
      bact.molecules <- MolMap.add m (1,p) bact.molecules


  (* il faudrait peut-être mettre dans une file les molécules à ajouter *)
  let rec execute_actions (actions : Transition.transition_effect list) (bact : t) : unit =
    match actions with
    | Transition.Release_effect mol :: actions' ->
       add_molecule mol bact;
       execute_actions actions' bact
    | Transition.Message_effect m :: actions' ->
       (* bact.message_queue <- m :: bact.message_queue; *)
       execute_actions actions' bact
    | [] -> ()

  let bind_to 
    (boundMol : Molecule.t) 
    (hostMol : Molecule.t) 
    (bindPattern : AcidTypes.bind_pattern)
    (bact : t)
    : unit = 
    
    let (_,p) = MolMap.find hostMol bact.molecules
    in 
    let reac_result = PetriNet.bind_mol boundMol bindPattern p
    in
    if reac_result
    then 
      bact.molecules <- MolMap.rel_change_mol_quantity boundMol (-1) bact.molecules
    else
      ()
      
  let make_bindings (bact : t) : unit = 
    ()


        
  let step_simulate (bact : t) : unit = 
    MolMap.iter
      (fun k x -> let (n, prot) = x in  
                  for i = 1 to n do
                    let actions = PetriNet.launch_random_transition prot in
                    execute_actions actions bact
                  done)
      bact.molecules;
    make_bindings bact
    (*    pop_all_messages bact *)
    
    
  let to_json (bact : t) =
    let mol_enum = MolMap.enum bact.molecules in
    let trimmed_mol_enum = Enum.map (fun (a,(b,c)) -> a,b) mol_enum in
    let trimmed_mol_list = List.of_enum trimmed_mol_enum in
    
    `Assoc [
       "molecules list",
       `List (List.map (fun (mol, nb) ->
                  `Assoc ["name", `String (Molecule.to_string mol);
                          "mol_json", Proteine.to_yojson (Molecule.to_prot mol);
                          "nb", `Int nb]) trimmed_mol_list)
     ]
      
end;;



  
