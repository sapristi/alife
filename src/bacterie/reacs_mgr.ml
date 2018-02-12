

open Misc_library
open Logs
open Batteries

   
let src = Logs.Src.create "reactions" ~doc:"logs reacs events";;
module Log = (val Logs.src_log src : Logs.LOG);;

(* * Reaction module *)
  
module rec Reaction : sig
         type active_md
         type inert_md
            
         type grab = { mutable rate : float;
                       graber_data : active_md;
                       grabed_data : inert_md;}
         val make_grab : active_md -> inert_md -> grab
         val grab_rate : active_md -> inert_md -> float
         type agrab = { mutable rate : float;
                       graber_data : active_md;
                       grabed_data : active_md;}
         val make_agrab : active_md -> active_md -> agrab
         val agrab_rate : active_md -> active_md -> float
           
         type transition= { mutable rate : float;
                            amd : active_md;}
         val make_transition : active_md -> transition
         val transition_rate : active_md -> float
         type t = 
           | Transition_r of transition ref
           | Grab_r of grab ref
           | AGrab_r of agrab ref

         val rate : t -> float
         val compare : t -> t -> int
         val show : t -> bytes
         val unlink : t -> unit
       end
  = struct
  
  type reaction_effect =
    | T_effects of Place.transition_effect list
    | Remove_pnet of Molecule.t * Petri_net.t ref
    | Update of ReacsSet.t ref
  
  type inert_md = {
      mol : Molecule.t;
      qtt : int ref; 
      reacs : ReacsSet.t ref; 
    }
   and active_md = {
       mol : Molecule.t;
       pnet : Petri_net.t ref;
       reacs : ReacsSet.t ref; 
     }

(* ** mol data *)
                       
  let compare_inert_md
        (imd1 : inert_md) (imd2 : inert_md) =
    String.compare imd1.mol imd2.mol
  let compare_active_md 
        (amd1 : active_md) (amd2 : active_md) =
    Pervasives.compare !(amd1.pnet).Petri_net.uid !(amd2.pnet).Petri_net.uid
    
  let pp_inert_md (f : Format.formatter)
                        (imd : inert_md)
    = ()
  let show_inert_md (imd : inert_md) =
    let res = Printf.sprintf "Inert mol : %s (%i)" imd.mol !(imd.qtt)
    in Bytes.of_string res

  let pp_active_md (f : Format.formatter)
                        (amd : active_md)
    = ()
  let show_active_md (amd : inert_md) =
    let res = Printf.sprintf "Active mol : %s" amd.mol
    in Bytes.of_string res

(* ** grab *)
     
  type grab = {
      mutable rate : float;
      graber_data : active_md;
      grabed_data : inert_md;
    }
                [@@ deriving ord, show]

  let grab_rate (amd : active_md) (imd : inert_md) =
    float_of_int (Petri_net.grab_factor imd.mol !(amd.pnet)) *.
      float_of_int !(imd.qtt) 

  let make_grab amd imd : grab =
    {
      rate = grab_rate amd imd;
      graber_data = amd;
      grabed_data = imd;}
    
(* ** agrab *)
  type agrab = {
      mutable rate : float;
      graber_data : active_md;
      grabed_data : active_md;
    }  
                 [@@ deriving ord, show]
             
  let agrab_rate (graber_d : active_md) (grabed_d : active_md) =
    1.
             
  let make_agrab graber_data grabed_data : agrab =
    {
      rate = agrab_rate graber_data grabed_data;
      graber_data;
      grabed_data;}
    
(* ** transition *)
  type transition = {
      mutable rate : float;
      amd : active_md;
    }
                      [@@ deriving ord, show]
                 
  let transition_rate (amd : active_md)  =
    (float_of_int !(amd.pnet).launchables_nb)
  let make_transition amd : transition =
    {
      rate = transition_rate amd;
      amd;
    }
    
  type t =
    | Transition_r of transition ref
    | Grab_r of grab ref
    | AGrab_r of agrab ref
[@@ deriving ord, show]

  let rate r  =
    match r with
    | Transition_r t -> (!t).rate
    | Grab_r g -> (!g).rate
    | AGrab_r ag -> (!ag).rate

                  
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

  let treat_reaction  (r : Reaction.t) :
      reaction_effect list =
  let effects = ref [] in
  match r with
  | Transition_r trans ->
     let pnet = (!trans).amd.pnet in
     let actions = Petri_net.launch_random_transition !pnet in
     Petri_net.update_launchables !pnet;
     effects :=
       Update (!trans).amd.reacs :: T_effects actions :: (!effects);
     !effects
     
  | Grab_r g ->
     let pnet =  !(g).graber_data.pnet in
     ignore (asymetric_grab (!g).grabed_data.mol !pnet);
     (!g).grabed_data.qtt := !((!g).grabed_data.qtt) -1;
     Petri_net.update_launchables !pnet;
     effects := Update (!g).grabed_data.reacs  ::
                     Update (!g).graber_data.reacs ::
                       (!effects);
     !effects
     (* we will need to take care of possible tokens inside the
        grabed pnet *)
  | AGrab_r g ->
     let pnet =  !(g).graber_data.pnet in
     ignore (asymetric_grab (!g).grabed_data.mol !pnet);
     Petri_net.update_launchables !pnet;
     effects := Update (!g).grabed_data.reacs  ::
                  Update (!g).graber_data.reacs ::
                    Remove_pnet (!(g).grabed_data.mol,
                                 !(g).grabed_data.pnet)
                    ::   (!effects);
     !effects
                  
  let unlink (r :t) =
    match r with
      | Transition_r t -> ()
      | Grab_r g ->    
         (* we remove reactions in both the graber and the grabed 
            even though only the graber can normally disappear,
            we allow the gui to remove inert molecules, plus it might
            help clean some stuff *)
         let ar = (!g).graber_data.reacs in
         ar := ReacsSet.remove r !ar; 
         let ir = (!g).grabed_data.reacs in
         ir := ReacsSet.remove r !ir;         
      | AGrab_r ag ->
         let ar = (!ag).graber_data.reacs in
         ar := ReacsSet.remove r !ar; 
         let ir = (!ag).grabed_data.reacs in
         ir := ReacsSet.remove r !ir;
                   
end
  
   and ReacsSet :
         sig
           include Set.S with type elt := Reaction.t
           val show : t -> string
         end
         = struct
         
         include Set.Make (Reaction)
               
         let show rset =
           fold (fun reac desc ->
               (Reaction.show reac)^"\n"^desc)
                rset
                ""

   end

         
            
            
type t =
  {
    mutable grabs : ReacsSet.t;
    mutable total_grabs_rate : float ;
    mutable agrabs : ReacsSet.t;
    mutable total_agrabs_rate : float;
    mutable transitions : ReacsSet.t;
    mutable total_transitions_rate : float;
    raw_grab_rate : float;
    raw_transition_rate : float;
  }
  
  
let make_new () : t =
  {
    grabs = ReacsSet.empty;
    total_grabs_rate = 0.;
    agrabs = ReacsSet.empty;
    total_agrabs_rate = 0.;
    (*    self_grabs = Set.empty;
          total_self_grabs_rate = 0.;  *)     
    transitions = ReacsSet.empty;
    total_transitions_rate = 0.;
    raw_grab_rate = 1.;
    raw_transition_rate = 10.;
  }
  
let remove_reactions reactions reac_mgr =
  ReacsSet.iter
    (fun (r : Reaction.t) ->
      match r with
      | Transition_r t -> 
         reac_mgr.transitions <- ReacsSet.remove r reac_mgr.transitions
      | Grab_r g ->
         reac_mgr.grabs <- ReacsSet.remove r reac_mgr.grabs;
         Reaction.unlink r;
         
      | AGrab_r ag ->
         reac_mgr.agrabs <- ReacsSet.remove r reac_mgr.agrabs;
         Reaction.unlink r;

    ) reactions


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

let add_grab graber_d grabed_d reacs : Reaction.t =
  let (g:Reaction.grab) = Reaction.make_grab graber_d grabed_d 
  in
  
  let r = Reaction.Grab_r (ref g) in
  reacs.grabs <- ReacsSet.add r reacs.grabs;
  reacs.total_grabs_rate <-
    g.rate +. reacs.total_grabs_rate;
  r
  
let update_grab_rate (rg : Reaction.grab ref) reacs =
  let old_rate  = !rg.rate 
  and new_rate = Reaction.grab_rate (!rg).graber_data (!rg).grabed_data
  in
  !rg.rate <- new_rate;
  reacs.total_grabs_rate <-
    reacs.total_grabs_rate -. old_rate +. new_rate

(* ** AGrabs *)

  
let add_agrab graber_d grabed_d reacs : Reaction.t =
  let (ag : Reaction.agrab) = Reaction.make_agrab graber_d grabed_d 
  in
  
  let r = Reaction.AGrab_r (ref ag) in
  reacs.agrabs <- ReacsSet.add r reacs.agrabs;
  reacs.total_agrabs_rate <-
    ag.rate +. reacs.total_agrabs_rate;
  r
  
let update_agrab_rate (rag : Reaction.agrab ref) reacs =
  let old_rate  = !rag.rate 
  and new_rate = Reaction.agrab_rate (!rag).graber_data (!rag).grabed_data 
  in
  !rag.rate <- new_rate;
  reacs.total_agrabs_rate <-
    reacs.total_agrabs_rate -. old_rate +. new_rate

  
(* ** Transitions *)
  
           
let add_transition amd reacs : Reaction.t =
  let t = Reaction.make_transition amd 
  in
  let rt = Reaction.Transition_r (ref t) in
  reacs.transitions <- ReacsSet.add rt reacs.transitions;
  reacs.total_transitions_rate <-
    t.rate +. reacs.total_transitions_rate;
  rt
  
let update_transition_rate (rt : Reaction.transition ref) reacs =
  let old_rate = (!rt).rate
  and new_rate = Reaction.transition_rate (!rt).amd in
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

(* replace to_list with to_enum ? *)
let pick_next_reaction (reacs:t) : Reaction.t option=


  Log.info (fun m -> m "picking next reaction in %s" "sqd");
  

  let a0 = reacs.total_grabs_rate
           +. reacs.total_agrabs_rate
           +. reacs.total_transitions_rate
  in
  if a0 = 0.
  then None
  else
  
  let r = Random.float 1. in
  let bound = r *. a0 in
  if bound < reacs.total_grabs_rate
  then
    let a0 = reacs.total_grabs_rate
    and r = Random.float 1. in
    let bound = r *. a0 in
    Some (
        (aux bound 0.
             Reaction.rate
             (ReacsSet.to_list reacs.grabs)))
  else if bound <  reacs.total_grabs_rate
                   +. reacs.total_agrabs_rate
  then
    let a0 = reacs.total_agrabs_rate
    and r = Random.float 1. in
    let bound = r *. a0 in
    Some
      (aux bound 0.
           Reaction.rate
           (ReacsSet.to_list reacs.agrabs))
  else
    let a0 = reacs.total_transitions_rate
    and r = Random.float 1. in
    let bound = r *. a0 in
    Some
      (aux bound 0.
           Reaction.rate
           (ReacsSet.to_list reacs.transitions))

let rec update_reaction_rates (reac : Reaction.t) reac_mgr=
  match reac with
  | Grab_r g -> update_grab_rate g reac_mgr
  | AGrab_r ag -> update_agrab_rate ag reac_mgr
  (*  | Self_grab sg -> update_self_grab_rate sg reac_mgr *)
  | Transition_r t -> update_transition_rate t reac_mgr


