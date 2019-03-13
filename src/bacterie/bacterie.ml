(* * this file *)


(* * libs *)
open Local_libs
open Reaction
(* compatibility with yojson before loading batteries *)
type ('a, 'b) mresult = ('a, 'b) result
open Reactants
open Yaac_config
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

(*  + ireactants : inactive reactants, molecules that do not fold into petri net. *)
(*  + areactants : active reactants, molecules that fold into a petri net. *)
(*     We thus have to have a distinct pnet for each present molecule *)

let logger = new Logger.rlogger "Bact"
               Config.logconfig.bact_log_level
               [Logger.Handler.Cli Debug]
   
type t ={
    mutable ireactants : IRMap.t;
    mutable areactants : ARMap.t;
    reac_mgr : Reac_mgr.t;
    env : Environment.t ref;
  }
type inert_bact_elem = {qtt:int;mol: Molecule.t;ambient:bool}
                     [@@ deriving yojson, ord, show]
type active_bact_elem = {qtt:int;mol: Molecule.t} 
                   [@@ deriving yojson, ord, show]
type bact_sig = {
    inert_mols : inert_bact_elem list;
    active_mols : active_bact_elem list;
  }
                 [@@ deriving yojson, show]

let canonical_bact_sig (bs : bact_sig) : bact_sig =
  {
    inert_mols = List.sort compare_inert_bact_elem (List.filter (fun (im : inert_bact_elem) -> im.qtt > 0) bs.inert_mols);
    active_mols = List.sort compare_active_bact_elem (List.filter (fun (am : active_bact_elem) -> am.qtt > 0) bs.active_mols);
  }


(* ** interface *)
  
(* Whenever modifying the bactery, it should be *)
(* done through these functions alone *)

  

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
     logger#info (Printf.sprintf "adding active molecule  : %s" mol);
     
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
     logger#info (Printf.sprintf "adding inactive molecule  : %s" mol);
       match MolMap.Exceptionless.find mol !(bact.ireactants) with
       | None -> 
          let new_rireac = ref (Reactant.ImolSet.make_new mol) in
          (* reactions : grabs *)
          ARMap.add_reacs_with_new_reactant
            (ImolSet new_rireac) bact.areactants bact.reac_mgr;
          
          (* reactions : break *)
          Reac_mgr.add_break (ImolSet new_rireac) bact.reac_mgr;
          (* add molecule *)
          bact.ireactants := MolMap.add !new_rireac.mol new_rireac
                                        !(bact.ireactants);
          [ Reacs.Update_reacs !(!new_rireac.reacs) ]
          
       | Some rireac ->
         IRMap.add_to_qtt !rireac 1 bact.ireactants
     )
    
  
    
(* *** remove molecule *)
(* totally removes a molecule from a bactery *)

let remove_one_reactant (reactant : Reactant.t) (bact : t) : Reacs.effect list =
  match reactant with
  | ImolSet ir ->
     IRMap.add_to_qtt !ir (-1) bact.ireactants
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
      logger#ldebug (lazy (Printf.sprintf "Executing effect %s"
                             (Reacs.show_effect effect)));
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
      | Update_launchables ramol ->
         Petri_net.update_launchables !ramol.pnet
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
  
  
let stats_logger = Logger.get_logger "reacs_stats"
                       
let next_reaction (bact : t)  =
  let reac_nb = lazy (Reac_mgr.get_reac_nb bact.reac_mgr) in
  let begin_time = Sys.time () in 
  let ro = Reac_mgr.pick_next_reaction bact.reac_mgr in
  let picked_time = Sys.time () in
  match ro with
  | None ->
     logger#warning "no more reactions";
     ()
  | Some r ->
     let ir_card = lazy (MolMap.cardinal !(bact.ireactants))
     and ar_card = lazy (ARMap.total_nb bact.areactants) in
     let actions = Reaction.treat_reaction r in
     let treated_time = Sys.time () in 
     execute_actions bact actions;
     let end_time = Sys.time () in

     stats_logger#linfo (
         lazy (
             let tnb, gnb, bnb = Lazy.force reac_nb in
             (Printf.sprintf "%d %d %d %d %d %f %f %f"
               (Lazy.force ir_card)
               (Lazy.force ar_card)
               tnb
               gnb
               bnb
               (picked_time -. begin_time)
               (treated_time -. picked_time)
               (end_time -. treated_time))
           ))
  
              
(* ** json serialisation *)
let from_sig (bact_sig : bact_sig) (bact : t): t  = 
  
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

  
  
let to_sig (bact : t) : bact_sig =
  let open Batteries in 
  let imol_enum = MolMap.enum !(bact.ireactants) in
  let trimmed_imol_enum =
    Enum.map (fun (a,(imd: Reactant.ImolSet.t ref)) ->
        ({mol = !imd.mol; qtt= !imd.qtt;
          ambient = !imd.ambient} : inert_bact_elem))
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
  {inert_mols = trimmed_imol_list;
   active_mols = trimmed_amol_list;}

let to_sig_yojson bact =
  bact_sig_to_yojson (to_sig bact)
  
let load_yojson_sig (json : Yojson.Safe.json) (bact :t ): (t,string) mresult =
  match  bact_sig_of_yojson json with
  | Ok bact_sig -> Ok (from_sig bact_sig bact)
  | Error s -> (Error s)


             
(* *** make empty *)
(* an empty bactery *)
  
  
let empty_sig : bact_sig = {
    inert_mols = [];
    active_mols = []}
  
let make ?(env=Environment.default_env)
         ?(bact_sig=empty_sig)  () :t =
  let renv = ref env in 
  
  let bact = {ireactants = ref MolMap.empty;
              areactants = ref MolMap.empty;
              env = renv;
              reac_mgr = Reac_mgr.make_new renv}
  in
  logger#info (Printf.sprintf "Creating new bactery from %s"
              (show_bact_sig bact_sig));
  from_sig bact_sig bact

  
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
