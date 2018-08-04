(* * this file *)


(* * libs *)
open Local_libs
open Reaction
(* compatibility with yojson before loading batteries *)
type ('a, 'b) mresult = ('a, 'b) result
open Batteries
open Amolset

(* * Container module *)

(* Une bacterie est un conteneur à molecules. Elle s'occupe de fournir  *)
(* l'interprétation d'une molécule en tant que protéine (i.e. pnet),  *)
(* puis d'organiser la simulation des pnet et de leurs interactions. *)

(* Pour organiser la simulation, il faut : *)
(*  - organiser le lancement des transitions *)
(*  - gérer les réactions *)

(* Pour rentrer dans le cadre Stochastic Simulations, *)
(* il faut associer à chaque réaction une probabilité. *)
(* Le calcul de la réaction suivante nécéssite de calculer la *)
(* proba de chacune des réactions, ce qui se fait en N² où N *)
(* est le NOMBRE total de molécules (c'est beaucoup trop). *)


(* ** types *)

              
module MolMap =
  struct
    include Map.Make (struct type t = Molecule.t
                             let compare = Pervasives.compare end)
                     (*   include Exceptionless *)
  end

  
(*  + ireactants : inactive reactants, molecules that do not fold into petri net. *)
(*  + areactants : active reactants, molecules that fold into a petri net. *)
(*     We thus have to have a distinct pnet for each present molecule *)
type t =

  {mutable ireactants : (Reactant.ImolSet.t ref) MolMap.t;
   mutable ireactants_qtt : int;
   mutable areactants : (ActiveMolSet.t) MolMap.t;
   mutable areactants_qtt : int;
   reac_mgr : Reac_mgr.t;
  }

(* ** module to interact with the active reactants *)
(*    + add, remove : *)
(*         takes a ref to an areactant and *)
(* 	adds it to (removes it from) the bactery *)
(*    + add_reacs_with_new_reactant : *)
(*         iterates through the present areactants to *)
(* 	add the possible reactions with the new reactant *)

module ARMgr =
  struct

    let add mol (areactant :Reactant.Amol.t ref)  bact =
      
      bact.areactants <-
        MolMap.modify_opt
          !areactant.mol
          (fun data ->
            match data with
            | Some amolset ->
               ActiveMolSet.add areactant amolset;
               Some amolset
            | None ->
               let new_amolset = ActiveMolSet.make_new mol in
               ActiveMolSet.add areactant new_amolset;
               Some (new_amolset)
          ) bact.areactants;
      bact.areactants_qtt <- bact.areactants_qtt + 1
      
      
    let remove (areactant : Reactant.Amol.t ref) bact =
      let amolset = MolMap.find !areactant.mol bact.areactants in
      ActiveMolSet.remove areactant amolset;
      bact.areactants_qtt <- bact.areactants_qtt - 1;
      Reac_mgr.remove_reactions !(!areactant.reacs) bact.reac_mgr
      
      
    let add_reacs_with_new_reactant (new_reactant : Reactant.t)
                                    (bact :t) reac_mgr : unit =
      MolMap.iter 
          (fun _ areac -> 
            ActiveMolSet.add_reacs_with_new_reactant
              new_reactant
              areac
              reac_mgr)
          bact.areactants
      
    let random_AR_pick (bact : t)=
      let b = Random.float (float_of_int (bact.areactants_qtt)) in
      let (amolset : ActiveMolSet.t) = 
        Misc_library.pick_from_enum
          b 
          (fun amols -> float_of_int (ActiveMolSet.qtt amols))
          (MolMap.values bact.areactants)
      in ActiveMolSet.random_pick amolset
  end

(* ** module to interact with inert reactants *)

module IRMgr =
  struct
    
    let add_to_qtt ir deltaqtt bact = 
      ir := Reactant.ImolSet.add_to_qtt deltaqtt !ir;
      bact.ireactants_qtt <- bact.ireactants_qtt + deltaqtt;
      Reac_mgr.update_rates !(!ir.reacs) bact.reac_mgr
      
    let set_qtt qtt mol bact = 
      let ir = MolMap.find mol bact.ireactants in
      let old_qtt = !ir.qtt in
      ir := Reactant.ImolSet.set_qtt qtt !ir;
      bact.ireactants_qtt <- bact.ireactants_qtt + qtt - old_qtt;
      Reac_mgr.update_rates !(!ir.reacs) bact.reac_mgr

    let set_ambient ambient mol bact =
      let ir = MolMap.find mol bact.ireactants in
      ir := Reactant.ImolSet.set_ambient ambient !ir
      
    let remove_all mol bact =
      let old_reacs = ref ReacSet.empty
      and old_qtt = ref 0 in
      bact.ireactants <-
        MolMap.modify_opt
          mol
          (fun data ->
            match data with
            | None -> failwith "container: cannot remove absent molecule"
            | Some imd ->
               old_reacs := Reactant.ImolSet.reacs !imd;
               old_qtt := Reactant.ImolSet.qtt !imd;
               None)
          bact.ireactants;
      bact.ireactants_qtt <- bact.ireactants_qtt - !old_qtt;
      Reac_mgr.remove_reactions !old_reacs bact.reac_mgr

    let remove_one ir bact = 
       ir := Reactant.ImolSet.add_to_qtt (-1) !ir;
       bact.ireactants_qtt <- bact.ireactants_qtt -1
      
    let add_reacs_with_new_reactant (new_reactant : Reactant.t)
                                    (bact :t) reac_mgr =      
      match new_reactant with
      | Amol new_amol -> 
         MolMap.iter
           (fun mol ireactant ->
             if Petri_net.can_grab mol !new_amol.pnet
             then Reac_mgr.add_grab new_amol new_reactant reac_mgr)
           bact.ireactants
              
      | ImolSet _ -> ()
      
    let random_pick (bact : t) =
      
      let b = Random.float (float_of_int (bact.ireactants_qtt)) in
          Misc_library.pick_from_enum
            b
            (fun imols -> float_of_int (Reactant.ImolSet.qtt !imols))
            (MolMap.values bact.ireactants)
             

  end
  

let random_reactant_pick bact = 
  let b = Random.int (bact.ireactants_qtt + bact.areactants_qtt) in
  if b < bact.ireactants_qtt
  then
    Reactant.ImolSet (IRMgr.random_pick bact)
  else
    Reactant.Amol (ARMgr.random_AR_pick bact)


  
(* ** interface *)
  
(* Whenever modifying the bactery, it should be *)
(* done through these functions alone *)

(* *** make empty *)
(* an empty bactery *)
  
let (default_rcfg : Reac_mgr.config) =
  {transition_rate = 10.;
   grab_rate = 1.;
   break_rate = 0.0000001;
   random_collision_rate = 0.0000001}
  
let make_empty ?(rcfg=default_rcfg) () =
  
  let bact = {ireactants = MolMap.empty;ireactants_qtt = 0;
              areactants = MolMap.empty;areactants_qtt = 0;
              reac_mgr = Reac_mgr.make_new rcfg;}
  in
  
  bact

  

(* *** add_molecule *)
(* adds single molecule to a container (bactery) We have to take care : *)
(*   - if the molecule is active, we must create a new active_reactant, *)
(*     add all possible reactions with this reactant, then add it to *)
(*     the bactery (whether or not other molecules of the same species *)
(*     were already present) *)
(*   - if the molecule is inactive, the situation depends on whether *)
(*     the species was present or not : *)
(*     + if it was already present, we modify it's quatity and update *)
(*       related reaction rates *)
(*     + if it was not, we add the molecules and the possible reactions *)
  
let add_molecule (mol : Molecule.t) (bact : t) : unit =
  let new_opnet = Petri_net.make_from_mol mol in
  match new_opnet with
    
  | Some pnet ->
     let areac = ref (Reactant.Amol.make_new pnet) in
     (* reactions : grabs with other amols*)
     ARMgr.add_reacs_with_new_reactant (Amol areac) bact bact.reac_mgr;
      
     (* reactions : grabs with inert mols *)
     IRMgr.add_reacs_with_new_reactant (Amol areac) bact bact.reac_mgr;
     
     (* reaction : transition  *)
     Reac_mgr.add_transition areac bact.reac_mgr;
     
     (* reaction : break *)
     Reac_mgr.add_break (Amol areac) bact.reac_mgr;
     
     (* we add the reactant after adding reactions 
        because it must not react with itself *)
     ARMgr.add mol areac bact
  | None ->
     (
       match MolMap.Exceptionless.find mol bact.ireactants with
       | None -> 
          let new_ireac = ref (Reactant.ImolSet.make_new mol) in
          (* reactions : grabs *)
          ARMgr.add_reacs_with_new_reactant
            (ImolSet new_ireac) bact bact.reac_mgr;
          
          (* reactions : break *)
          Reac_mgr.add_break (ImolSet new_ireac) bact.reac_mgr;
          (* add molecule *)
          bact.ireactants <-
            MolMap.add !new_ireac.mol (new_ireac)
                       bact.ireactants;
          bact.ireactants_qtt <- bact.ireactants_qtt +1
          
       |Some ireac ->
         IRMgr.add_to_qtt ireac 1 bact;
     )
    
  
    
(* *** remove molecule *)
(* totally removes a molecule from a bactery *)

let remove_one_reactant (reactant : Reactant.t) (bact : t) : unit =
  match reactant with
  | ImolSet ir ->
     IRMgr.remove_one ir bact
  | Amol amol ->
     ARMgr.remove amol bact
  
(* **** execute_actions *)
(* after a transition from a proteine has occured, *)
(*    some actions may need to be performed by the bactery *)
(*   for now, only the release effect is in use *)
(*   todo later : ??? *)
(*   il faudrait peut-être mettre dans une file les molécules à ajouter *)

let rec execute_actions (actions : Reacs.effect list) (bact : t) : unit =
  List.iter
    (fun (effect : Reacs.effect) ->
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
      | Update_reacs reacset ->
         Reac_mgr.update_rates reacset bact.reac_mgr
      | Remove_one reactant ->
         remove_one_reactant reactant bact
      | Release_mol mol -> add_molecule mol bact
      | Release_tokens tlist ->
         List.iter (fun (n,mol) ->
             add_molecule mol bact) tlist
    (* Possible effects : 
       - forced grab : a molecule is fitted into a pnet
         even though a grab could not possibly occur
         (this could be parameterized with
         some kind of bind probability)
      - mix : the molecules are mixed together,
      or one is put into the other one
      - both break
     *)
    )
    actions
  
  
let next_reaction (bact : t)  =
  let ro = Reac_mgr.pick_next_reaction bact.reac_mgr in
  match ro with
  | None -> failwith "next_reaction @ bacterie : no more reactions"
  | Some r ->
     let actions = Reaction.treat_reaction r in
     execute_actions actions bact

  
              
(* ** json serialisation *)
type inert_bact_elem = {qtt:int;mol: Molecule.t;ambient:bool}
                     [@@ deriving yojson]
type active_bact_elem = {qtt:int;mol: Molecule.t} 
                   [@@ deriving yojson]
type bact_sig = {
    inert_mols : inert_bact_elem list;
    active_mols : active_bact_elem list;
  }
                 [@@ deriving yojson]
              
let make (bact_sig : bact_sig) :t  = 
  let bact = make_empty () in
    List.iter
    (fun {mol = m;qtt = n; ambient=a} ->
      add_molecule m bact;
      IRMgr.set_qtt n m bact;
      IRMgr.set_ambient a m bact;
    ) bact_sig.inert_mols;
  
    List.iter
    (fun {mol = m; qtt = n} ->
      for i = 0 to n-1 do 
        add_molecule m bact;
      done;)
    bact_sig.active_mols;
  bact

  
let to_yojson (bact : t) : Yojson.Safe.json =
  let imol_enum = MolMap.enum bact.ireactants in
  let trimmed_imol_enum =
    Enum.map (fun (a,(imd: Reactant.ImolSet.t ref)) ->
        ({mol= !imd.mol; qtt= !imd.qtt;
          ambient= !imd.ambient} : inert_bact_elem))
             imol_enum in
  let trimmed_imol_list = List.of_enum trimmed_imol_enum in
  
  let amol_enum = MolMap.enum bact.areactants in
  let trimmed_amol_enum =
    Enum.map (fun (a, amolset) ->
        {mol = a; qtt = ActiveMolSet.qtt amolset;})
             amol_enum
  in
  let trimmed_amol_list = List.of_enum trimmed_amol_enum
  in  
  bact_sig_to_yojson {inert_mols = trimmed_imol_list;
                      active_mols = trimmed_amol_list;}


let of_yojson (json : Yojson.Safe.json) : (t,string) mresult =
  match  bact_sig_of_yojson json with
  | Ok bact_sig -> Ok (make bact_sig)
  | Error s -> (Error s)
             
  
module SimControl =
  struct
    
      
(* *** add_proteine *)
(* adds the molecule corresponding to a proteine to a bactery first transforms it back to a molecule, so the *)
(* process is not very natural. *)
(* ***** SHOULD NOT BE USED *)

    let add_proteine (prot : Proteine.t) (bact : t) : unit =
      let mol = Molecule.of_proteine prot in
      add_molecule mol bact

    
end
