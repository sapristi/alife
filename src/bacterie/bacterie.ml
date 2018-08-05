(* * this file *)


(* * libs *)
open Local_libs
open Reaction
(* compatibility with yojson before loading batteries *)
type ('a, 'b) mresult = ('a, 'b) result
open Batteries

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

  

(* ** module to interact with the active reactants *)
(*    + add, remove : *)
(*         takes a ref to an areactant and *)
(* 	adds it to (removes it from) the bactery *)
(*    + add_reacs_with_new_reactant : *)
(*         iterates through the present areactants to *)
(* 	add the possible reactions with the new reactant *)

module ARMap =
  struct
    
    module AmolSet =
      struct
        include Set.Make (
                 struct
                   type t = Reactant.Amol.t ref
                   let compare =
                     fun (amd1 :t) (amd2:t) ->
                     Reactant.Amol.compare
                       !amd1 !amd2
                 end)
           

        let find_by_id pnet_id amolset  =
          let (dummy_pnet : Petri_net.t) ={
              mol = ""; transitions = [||];places = [||];
              uid = pnet_id;
              launchables_nb = 0;} in
          let dummy_amd = ref (Reactant.Amol.make_new dummy_pnet)
          in
          !(find dummy_amd amolset).pnet
          
              
        let add_reacs_with_new_reactant (new_reactant : Reactant.t) (amolset :t) reac_mgr : unit =
          if is_empty amolset
          then
            ()
          else
            let (any_amd : Reactant.Amol.t ref) = any amolset in
            let dummy_pnet = !(any_amd).pnet in
            
            match new_reactant with
            | Amol new_amol ->
               
               let is_graber = Petri_net.can_grab
                                 (Reactant.mol new_reactant)
                                 dummy_pnet
               and is_grabed = Petri_net.can_grab
                                dummy_pnet.mol
                                !new_amol.pnet  in
               
               iter
                 (fun current_amd ->
                   if is_graber
                   then
                     Reac_mgr.add_grab new_amol (Amol current_amd) reac_mgr;
                   
                   if is_grabed
                   then 
                     Reac_mgr.add_grab current_amd new_reactant reac_mgr;
                 ) amolset;
               
               
            | ImolSet _ -> 
               if Petri_net.can_grab (Reactant.mol new_reactant) dummy_pnet
               then 
                 
                 iter
                   (fun current_amol ->
                     Reac_mgr.add_grab current_amol new_reactant reac_mgr)
                   amolset
               
      
      end

      
    type t = AmolSet.t MolMap.t ref
           
    let add (areactant :Reactant.Amol.t ref)  (armap : t) : Reacs.effect list =
      armap :=
        MolMap.modify_opt
          !areactant.mol
          (fun data ->
            match data with
            | Some amolset ->
               Some ( AmolSet.add areactant amolset )
            | None ->
               Some( AmolSet.singleton areactant )
          ) !armap;
      (* we should return the list of reactions to update *)
      [ Reacs.Update_reacs !((!areactant).reacs)]

      
      
    let remove (areactant : Reactant.Amol.t ref) (armap : t) : Reacs.effect list =
      armap :=
        MolMap.modify
          !areactant.mol
          (fun  amolset ->  AmolSet.remove areactant amolset )
          !armap;
        
      [ Reacs.Remove_reacs !((!areactant).reacs)]
      
    let get_pnet_ids mol (armap :t) =
      MolMap.find mol !armap
      |> AmolSet.enum
      |> Enum.map  (fun (amd : Reactant.Amol.t ref) ->
             (!amd).pnet.uid)
      |> List.of_enum

    let find_pnet mol pnet_id (armap : t) : Petri_net.t =
      MolMap.find mol !armap
      |> AmolSet.find_by_id pnet_id
      
      
    let add_reacs_with_new_reactant (new_reactant : Reactant.t)
                                    (armap :t)  reac_mgr: unit =
      
      MolMap.iter 
        (fun _ areac -> 
          AmolSet.add_reacs_with_new_reactant
            new_reactant
            areac
            reac_mgr)
        !armap
      
  end

(* ** module to interact with inert reactants *)

module IRMap =
  struct
    type t = (Reactant.ImolSet.t) MolMap.t ref

           
    let add_to_qtt (ir : Reactant.ImolSet.t) deltaqtt (irmap : t)
        : Reacs.effect list =
      irmap :=
        MolMap.modify
          ir.mol
          (fun  imolset -> Reactant.ImolSet.add_to_qtt deltaqtt imolset)
          !irmap;
      [Reacs.Update_reacs !(ir.reacs)]
      
    let set_qtt qtt mol (irmap : t)  : Reacs.effect list= 
      let ir = MolMap.find mol !irmap in
      irmap :=
        MolMap.modify
          ir.mol
          (fun  imolset -> Reactant.ImolSet.set_qtt qtt imolset)
          !irmap;
      [ Reacs.Update_reacs !(ir.reacs)]
      
    let set_ambient ambient mol irmap =
      irmap :=
        MolMap.modify
          mol
          (fun  imolset -> Reactant.ImolSet.set_ambient ambient imolset)
          !irmap
      
      
    let remove_all mol (irmap : t) =
      let old_reacs = ref ReacSet.empty
      and old_qtt = ref 0 in
      irmap :=
        MolMap.modify_opt
          mol
          (fun data ->
            match data with
            | None -> failwith "container: cannot remove absent molecule"
            | Some imd ->
               old_reacs := Reactant.ImolSet.reacs imd;
               old_qtt := Reactant.ImolSet.qtt imd;
               None)
          !irmap;
      
      [ Reacs.Remove_reacs !old_reacs]

    let remove_one ir (irmap : t) =
      add_to_qtt ir (-1) irmap
      
    let add_reacs_with_new_reactant (new_reactant : Reactant.t)
                                    (irmap :t) reac_mgr =      
      match new_reactant with
      | Amol new_amol -> 
         MolMap.iter
           (fun mol ireactant ->
             if Petri_net.can_grab mol !new_amol.pnet
             then Reac_mgr.add_grab new_amol new_reactant reac_mgr)
           !irmap
        
      | ImolSet _ -> ()
      
        
  end
  


(*  + ireactants : inactive reactants, molecules that do not fold into petri net. *)
(*  + areactants : active reactants, molecules that fold into a petri net. *)
(*     We thus have to have a distinct pnet for each present molecule *)
type t =

  {mutable ireactants : IRMap.t;
   mutable areactants : ARMap.t;
   reac_mgr : Reac_mgr.t;
  }
  
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
  
  let bact = {ireactants = ref MolMap.empty;
              areactants = ref MolMap.empty;
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
  
let add_molecule (mol : Molecule.t) (bact : t) : Reacs.effect list =
  let new_opnet = Petri_net.make_from_mol mol in
  match new_opnet with
    
  | Some pnet ->
     let ar = ref (Reactant.Amol.make_new pnet) in
     (* reactions : grabs with other amols*)
     ARMap.add_reacs_with_new_reactant (Amol ar) bact.areactants bact.reac_mgr;
      
     (* reactions : grabs with inert mols *)
     IRMap.add_reacs_with_new_reactant (Amol ar) bact.ireactants bact.reac_mgr;
     
     (* reaction : transition  *)
     Reac_mgr.add_transition ar bact.reac_mgr;
     
     (* reaction : break *)
     Reac_mgr.add_break (Amol ar) bact.reac_mgr;
     
     (* we add the reactant after adding reactions 
        because it must not react with itself *)
     ARMap.add ar bact.areactants
  | None ->
     (
       match MolMap.Exceptionless.find mol !(bact.ireactants) with
       | None -> 
          let new_ireac = ref (Reactant.ImolSet.make_new mol) in
          (* reactions : grabs *)
          ARMap.add_reacs_with_new_reactant
            (ImolSet new_ireac) bact.areactants bact.reac_mgr;
          
          (* reactions : break *)
          Reac_mgr.add_break (ImolSet new_ireac) bact.reac_mgr;
          (* add molecule *)
          bact.ireactants := MolMap.add !new_ireac.mol (!new_ireac)
                                        !(bact.ireactants);
          [ Reacs.Update_reacs !(!new_ireac.reacs) ]
          
       | Some ireac ->
         IRMap.add_to_qtt ireac 1 bact.ireactants
     )
    
  
    
(* *** remove molecule *)
(* totally removes a molecule from a bactery *)

let remove_one_reactant (reactant : Reactant.t) (bact : t) : Reacs.effect list =
  match reactant with
  | ImolSet ir ->
     IRMap.remove_one !ir bact.ireactants
  | Amol amol ->
     ARMap.remove amol bact.areactants

  
(* **** execute_actions *)
(* after a transition from a proteine has occured, *)
(*    some actions may need to be performed by the bactery *)
(*   for now, only the release effect is in use *)
(*   todo later : ??? *)
(*   il faudrait peut-être mettre dans une file les molécules à ajouter *)

let rec execute_actions (bact :t) (actions : Reacs.effect list) : unit =
  List.iter
    (fun (effect : Reacs.effect) ->
      match effect with
      | T_effects tel ->
         List.iter
           (fun teffect ->
             match teffect with
             | Place.Release_effect mol  ->
                if mol != ""
                then
                  add_molecule mol bact
                  |> execute_actions bact
             | Place.Message_effect m  ->
             (* bact.message_queue <- m :: bact.message_queue; *)
                ()
           ) tel
      | Update_reacs reacset ->
         Reac_mgr.update_rates reacset bact.reac_mgr
      | Remove_reacs reacset -> 
         Reac_mgr.remove_reactions reacset bact.reac_mgr
      | Remove_one reactant ->
         remove_one_reactant reactant bact
         |> execute_actions bact
      | Release_mol mol ->
         add_molecule mol bact
         |> execute_actions bact
      | Release_tokens tlist ->
         List.iter (fun (n,mol) ->
             add_molecule mol bact
             |> execute_actions bact) tlist
         
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
     execute_actions bact actions 

  
              
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
      add_molecule m bact
      |> execute_actions bact;
      IRMap.set_qtt n m bact.ireactants
      |> execute_actions bact;
      IRMap.set_ambient a m bact.ireactants;
    ) bact_sig.inert_mols;
  
    List.iter
    (fun {mol = m; qtt = n} ->
      for i = 0 to n-1 do 
        add_molecule m bact
        |> execute_actions bact;
      done;)
    bact_sig.active_mols;
  bact

  
let to_yojson (bact : t) : Yojson.Safe.json =
  let imol_enum = MolMap.enum !(bact.ireactants) in
  let trimmed_imol_enum =
    Enum.map (fun (a,(imd: Reactant.ImolSet.t )) ->
        ({mol= imd.mol; qtt= imd.qtt;
          ambient= imd.ambient} : inert_bact_elem))
             imol_enum in
  let trimmed_imol_list = List.of_enum trimmed_imol_enum in
  
  let amol_enum = MolMap.enum !(bact.areactants) in
  let trimmed_amol_enum =
    Enum.map (fun (a, amolset) ->
        {mol = a; qtt = ARMap.AmolSet.cardinal amolset;})
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
      |> execute_actions bact

    
end
