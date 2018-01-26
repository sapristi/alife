

open Misc_library
open Logs
   
type mol_data =
  {mol : Molecule.t;
   qtt : int ref;
   pnet : Petri_net.t option ref; [@opaque]
  }
[@@deriving show]
(* TODO : manque self_collision 
avec taux de réaction approprié *)
type grab = {
    mutable rate : float;
    graber_data : mol_data;
    grabed_data : mol_data;
  }
              [@@deriving show]
type self_grab =
  {
    mutable rate : float;
    md : mol_data;
  }
              [@@deriving show]
          
type transition = {
    mutable rate : float;
    md : mol_data;
  }
                    [@@deriving show]

type reaction =
  | Transition of transition ref
  | Grab of grab ref
  | Self_grab of self_grab ref
  | No_reaction
[@@deriving show]

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
    [@@deriving show]

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

let grab_rate (md1 : mol_data) (md2 : mol_data) reacs=
  match !(md1.pnet) with
     |  Some pnet1 ->
         float_of_int !(md1.qtt) *. float_of_int !(md2.qtt) *. reacs.raw_grab_rate
         *. (float_of_int (Petri_net.grab_factor md2.mol pnet1))
     | None -> failwith "grab_rate@reactions_new: should have a pnet"
             
let add_grab md1 md2 reacs : reaction =
  let c = {
      rate = grab_rate md1 md2 reacs;
      graber_data = md1;
      grabed_data = md2;
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

let self_grab_rate (md : mol_data) reacs=
     match !(md.pnet) with
     | Some pnet ->
        float_of_int !(md.qtt) *. (1. -. float_of_int !(md.qtt))
        *. reacs.raw_grab_rate
        *. (float_of_int (Petri_net.grab_factor (md.mol) pnet))
     | None ->   failwith "self_grab_rate@reactions_new: should have a pnet"
               
let add_self_grab (md : mol_data) reacs : reaction =
  let (sg : self_grab) = {
      rate = self_grab_rate md reacs;
      md = md;
    }
  in
  let rsg = ref sg in
  reacs.self_grabs <- rsg :: reacs.self_grabs;
  reacs.total_grabs_rate <-
    sg.rate +. reacs.total_grabs_rate;
  Self_grab rsg
  
let update_self_grab_rate (rc : self_grab ref) reacs =
  let old_rate  = !rc.rate 
  and new_rate = self_grab_rate !(rc).md  reacs
  in
  !rc.rate <- new_rate;
  reacs.total_self_grabs_rate <-
    reacs.total_self_grabs_rate -. old_rate +. new_rate

  
(* ** Transitions *)
  
let transition_rate (md : mol_data) reacs =
  match !(md.pnet) with
  |Some pnet ->
    float_of_int !(md.qtt) *. (float_of_int pnet.launchables_nb) *.
      reacs.raw_transition_rate
  | None -> failwith "tzezo"
           
let add_transition md reacs : reaction =
  let t = {
      rate = transition_rate md reacs;
      md = md;
    }
  in
  let rt = ref t in
  reacs.transitions <- rt :: reacs.transitions;
  reacs.total_transitions_rate <-
    t.rate +. reacs.total_transitions_rate;
  Transition rt
  
let update_transition_rate (rt : transition ref) reacs =
  let old_rate = (!rt).rate
  and new_rate = transition_rate (!rt).md reacs in
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
  Logs.debug (fun m -> m "%s" (show reacs));

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
     (
     let opnet = !((!trans).md.pnet) in
     match opnet with
     | Some pnet ->
        let actions = Petri_net.launch_random_transition pnet in
        Petri_net.update_launchables pnet;
        effects :=
          Update (!trans).md.mol :: T_effects actions :: (!effects);
     | None -> failwith "sdfs"
     );
     !effects
  | Grab g ->
     (
     match !(!(g).graber_data.pnet) with
     | Some pnet ->
        ignore (asymetric_grab (!g).grabed_data.mol pnet);
        (!g).grabed_data.qtt := !((!g).grabed_data.qtt) -1;
        Petri_net.update_launchables pnet;
        effects := Update (!g).grabed_data.mol  ::
                     Update (!g).graber_data.mol ::
                       (!effects);
     !effects
     | None -> failwith "dg"
     )
  | Self_grab sg ->
     (
     match !(!(sg).md.pnet) with
     | Some pnet ->
        ignore (asymetric_grab  (!sg).md.mol pnet);
        Petri_net.update_launchables pnet;
        effects := Update (!sg).md.mol  :: (!effects);
        !effects
     | None -> failwith "dsf"
     )
  | No_reaction -> []
