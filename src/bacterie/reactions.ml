

open Misc_library
open Logs
open Batteries

   
type reacsSet = reaction Set.t
   
 and inactive_mol_data = {
     mol : Molecule.t;
     qtt : int ref;
     reacs : reacsSet ref;
  }
                       
 and active_mol_data = {
     mol : Molecule.t;
     pnet : Petri_net.t;
     reacs : reacsSet ref; 
  }
                     
 and grab = {
    mutable rate : float;
    graber_data : active_mol_data;
    grabed_data : inactive_mol_data;
   }
          
 and self_grab =
   {
    mutable rate : float;
    amd : active_mol_data;
    imd : inactive_mol_data;
   }
   
   
 and transition = {
     mutable rate : float;
     amd : active_mol_data;
   }
                    

and reaction =
  | Transition of transition ref
  | Grab of grab ref
  | Self_grab of self_grab ref
  | No_reaction


type reaction_effect =
  | T_effects of Place.transition_effect list
  | Update of Molecule.t
            
type t =
  {
    mutable grabs : grab ref list;
    mutable total_grabs_rate : float ;
    mutable self_grabs : self_grab ref list;
    mutable total_self_grabs_rate : float;
    mutable transitions : transition ref list;
    mutable total_transitions_rate : float;
    raw_grab_rate : float;
    raw_transition_rate : float;
  }
    

let make_new () : t =
  {
    grabs = [];
    total_grabs_rate = 0.;
    self_grabs = [];
    total_self_grabs_rate = 0.; 
    transitions = [];
    total_transitions_rate = 0.;
    raw_grab_rate = 1.;
    raw_transition_rate = 10.;
  }
  
(* **** collision *)
(*     The collision probability between two molecules is *)
(*     the product of their quantities. *)
(*     We might need to add other parameters, such as *)
(*     the volume of the container, and use a float constant *)
(*     to avoid integer overflow. *)
(*     We here calculate each collision probability, *)
(*     and the sum of it. *)
(*     WARNING : possible integer overflow *) 
(* https://fr.wikipedia.org/wiki/Th%C3%A9orie_des_collisions *)

(* ** Grabs *)

let grab_rate (amd : active_mol_data) (imd : inactive_mol_data) reacs=
  float_of_int !(imd.qtt) *. reacs.raw_grab_rate
  
let add_grab amd imd reacs : reaction =
  let c = {
      rate = grab_rate imd amd reacs;
      graber_data = imd;
      grabed_data = amd;
    }
  in
  
  let rc = ref c in
  reacs.grabs <- rc :: reacs.grabs;
  reacs.total_grabs_rate <-
    c.rate +. reacs.total_grabs_rate;
  Grab rc
  
let update_grab_rate (rc : grab ref) reacs =
  let old_rate  = !rc.rate 
  and new_rate = grab_rate (!rc).graber_data (!rc).grabed_data reacs
  in
  !rc.rate <- new_rate;
  reacs.total_grabs_rate <-
    reacs.total_grabs_rate -. old_rate +. new_rate

(* ** Self grabs *)

let self_grab_rate (amd : active_mol_data) (imd : inactive_mol_data) reacs=
  (float_of_int !(imd.qtt) -. 1.)
  *. reacs.raw_grab_rate
  *. (float_of_int (Petri_net.grab_factor (imd.mol) amd.pnet))
               
let add_self_grab (amd : active_mol_data) (imd : inactive_mol_data) reacs : reaction =
  let (sg : self_grab) = {
      rate = self_grab_rate amd imd reacs;
      amd = amd;
      imd = imd;
    }
  in
  let rsg = ref sg in
  reacs.self_grabs <- rsg :: reacs.self_grabs;
  reacs.total_grabs_rate <-
    sg.rate +. reacs.total_grabs_rate;
  Self_grab rsg
  
let update_self_grab_rate (rc : self_grab ref) reacs =
  let old_rate  = !rc.rate 
  and new_rate = self_grab_rate !(rc).amd !(rc).imd reacs
  in
  !rc.rate <- new_rate;
  reacs.total_self_grabs_rate <-
    reacs.total_self_grabs_rate -. old_rate +. new_rate

  
(* ** Transitions *)
  
let transition_rate (amd : active_mol_data) reacs =
  (float_of_int amd.pnet.launchables_nb) *.
    reacs.raw_transition_rate
           
let add_transition amd reacs : reaction =
  let t = {
      rate = transition_rate amd reacs;
      amd = amd;
    }
  in
  let rt = ref t in
  reacs.transitions <- rt :: reacs.transitions;
  reacs.total_transitions_rate <-
    t.rate +. reacs.total_transitions_rate;
  Transition rt
  
let update_transition_rate (rt : transition ref) reacs =
  let old_rate = (!rt).rate
  and new_rate = transition_rate (!rt).amd reacs in
  !rt.rate <- new_rate;
  reacs.total_transitions_rate <-
    reacs.total_transitions_rate -. old_rate +. new_rate       

(* ** pick next reaction *)
let rec aux
          (b : float) (c : float)
          (r_access : 'a -> float)
          (l : 'a list)  = 
  match l with
  | h::t ->
     let c' = c +. (r_access h) in
     if c' > b then h
     else aux b c' r_access t
  | [] -> failwith "pick_reaction @ reactions.ml : can't find reaction"
        
let pick_next_reaction (reacs:t) : reaction =

  let a0 = reacs.total_grabs_rate +. reacs.total_transitions_rate in
  if a0 = 0.
  then No_reaction
  else
  
  let r = Random.float 1. in
  let bound = r *. a0 in
  if bound < reacs.total_grabs_rate
  then
    let a0 = reacs.total_grabs_rate
    and r = Random.float 1. in
    let bound = r *. a0 in
    Grab
      (aux bound 0.
           (fun (col : grab ref) -> (!col).rate)
           reacs.grabs)
  else  
    let a0 = reacs.total_transitions_rate
    and r = Random.float 1. in
    let bound = r *. a0 in
    Transition
      (aux bound 0.
           (fun (tr : transition ref) -> (!tr).rate)
           reacs.transitions)

let rec update_reaction_rates (reac : reaction) reac_mgr=
  match reac with
  | Grab g -> update_grab_rate g reac_mgr
  | Self_grab sg -> update_self_grab_rate sg reac_mgr
  | Transition t -> update_transition_rate t reac_mgr
  | No_reaction ->()


(* **** asymetric_grab *)
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

let oasymetric_grab mol opnet =
  match opnet with
  | Some pnet -> asymetric_grab mol pnet
  | None -> failwith "oasymetric_grab @ bacterie.ml : there should be a pnet"

(* to be moved to the reactions modules *)
let treat_reaction  (r : reaction) :
      reaction_effect list =
  let effects = ref [] in
  match r with
  | Transition trans ->
     let pnet = (!trans).amd.pnet in
     let actions = Petri_net.launch_random_transition pnet in
     Petri_net.update_launchables pnet;
     effects :=
       Update (!trans).amd.mol :: T_effects actions :: (!effects);
     !effects
     
  | Grab g ->
     let pnet =  !(g).graber_data.pnet in
     ignore (asymetric_grab (!g).grabed_data.mol pnet);
     (!g).grabed_data.qtt := !((!g).grabed_data.qtt) -1;
     Petri_net.update_launchables pnet;
     effects := Update (!g).grabed_data.mol  ::
                     Update (!g).graber_data.mol ::
                       (!effects);
     !effects
     
  | Self_grab sg ->
     let pnet =  !(sg).amd.pnet in
        ignore (asymetric_grab  (!sg).amd.mol pnet);
        Petri_net.update_launchables pnet;
        effects := Update (!sg).amd.mol  :: (!effects);
        !effects
  | No_reaction -> []
