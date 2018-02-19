

open Logs
open Batteries
open Reaction
   
let src = Logs.Src.create "reactions" ~doc:"logs reacs events";;
module Log = (val Logs.src_log src : Logs.LOG);;

(* * Reaction module *)
module type REACSET =
  sig
    type elt
    module RSet :
    sig
        include Set.S with type elt = elt
        val show : t -> string
    end
    type t = {mutable total_rate : float;
              mutable set : RSet.t;
              modifier : float}

    val make_empty : float -> t
  end
  
  
module MakeReacSet (Reac : Reactions.REAC) : (REACSET with type elt = Reac.t )
  = struct
  type elt = Reac.t
  module RSet=
    struct
      include Set.Make(Reac)  
      let show (s : t) =
        fold (fun (e : elt) desc ->
            (Reac.show e)^"\n"^desc) s ""
    end
  type t = {mutable total_rate : float;
            mutable set : RSet.t;
            modifier : float}
  let make_empty (modifier : float) : t =
    {total_rate = 0.;
     set = RSet.empty;
     modifier;}
end

let build_reac_set
      (type a)
      (module Reac : Reactions.REAC with type t = a)
  = 
  (module struct
     
     module RSet =
       struct
         include Set.Make(Reac)
         let show (s : t) =
           fold (fun (e : elt) desc ->
               (Reac.show e)^"\n"^desc) s ""
       end

     type elt = RSet.elt
     type t = {mutable total_rate : float;
               mutable set : RSet.t;
               modifier : float}
     let make_empty (modifier : float) : t =
       {total_rate = 0.;
        set = RSet.empty;
        modifier;}
   end : REACSET with type elt = Reac.t)


let grabRSet = (module MakeReacSet(Grab) :
                REACSET with type elt = Grab.t)
let agrabRSet = (module MakeReacSet(AGrab) :
                 REACSET with type elt = AGrab.t)
let transitionRSet = (module MakeReacSet(Transition) :
                      REACSET with type elt = Transition.t)


  
module type ReacSetInstance = sig
  module ReacSet : REACSET
  type elt
  val this : ReacSet.t
end;;

let build_instance
      (type a)
      (module RS : REACSET with type elt = a)
      modifier
  =
  (module struct
     module ReacSet = RS 
     let this = RS.make_empty modifier
     type elt = a
   end : ReacSetInstance)


type t =
  { t_set :  (module ReacSetInstance with type elt = Transition.t);
    g_set :  (module ReacSetInstance with type elt = Grab.t) ;
    ag_set :  (module ReacSetInstance with type elt = AGrab.t);
  }
    
let remove_reactions reactions reac_mgr =
  ReacsSet.iter
    (fun (r : Reaction.t) ->
      match r with
      | Transition t ->
         let (module R : ReacSetInstance with type elt = Transition.t) = reac_mgr.t_set in
         R.this.set <- R.ReacSet.RSet.remove !t R.this.set
         
      | Grab g ->
         reac_mgr.grabs <-
           GrabsSet.remove !g reac_mgr.grabs;
         Grab.unlink !g;
         
      | AGrab ag ->
         reac_mgr.agrabs <-
           AGrabsSet.remove !ag reac_mgr.agrabs;
         AGrab.unlink !r;

    ) reactions
(*
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

let add_grab (graber_d : Reaction.active_md)
             (grabed_d : Reaction.inert_md) reacs  =
  let (g:Grab.t) = Grab.make (graber_d,grabed_d) 
  in

  Log.debug (fun m -> m "added new grab between : %s\n%s"
                        (Reaction.show_active_md graber_d)
                        (Reaction.show_inert_md grabed_d));
  
  let r = Reaction.Grab (ref g) in
  reacs.grabs <- GrabsSet.add g reacs.grabs;

  Reaction.add_reac_to_active_md r graber_d;
  Reaction.add_reac_to_inert_md r grabed_d;
  
  reacs.total_grabs_rate <-
    g.rate +. reacs.total_grabs_rate
  
let update_grab_rate (rg : Reaction.grab ref) reacs =
  let old_rate  = !rg.rate 
  and new_rate = Reaction.grab_rate (!rg).graber_data (!rg).grabed_data
  in
  !rg.rate <- new_rate;
  reacs.total_grabs_rate <-
    reacs.total_grabs_rate -. old_rate +. new_rate

(* ** AGrabs *)

  
let add_agrab (graber_d : Reaction.active_md)
              (grabed_d : Reaction.active_md) reacs  =
  let (ag : Reaction.agrab) = Reaction.make_agrab graber_d grabed_d 
  in
  
  Log.debug (fun m -> m "added new agrab between : %s\n%s"
                        (Reaction.show_active_md graber_d)
                        (Reaction.show_active_md grabed_d));
  let r = Reaction.AGrab (ref ag) in
  reacs.agrabs <- AGrabsSet.add ag reacs.agrabs;

  Reaction.add_reac_to_active_md r graber_d;
  Reaction.add_reac_to_active_md r grabed_d;
  
  reacs.total_agrabs_rate <-
    ag.rate +. reacs.total_agrabs_rate
  
let update_agrab_rate (rag : Reaction.agrab ref) reacs =
  let old_rate  = !rag.rate 
  and new_rate = Reaction.agrab_rate (!rag).graber_data (!rag).grabed_data 
  in
  !rag.rate <- new_rate;
  reacs.total_agrabs_rate <-
    reacs.total_agrabs_rate -. old_rate +. new_rate

  
(* ** Transitions *)
  
           
let add_transition amd reacs  =
  let t = Reaction.make_transition amd 
  in

  Log.debug (fun m -> m "added new transition : %s"
                        (Reaction.show_active_md amd));
  
  let rt = Reaction.Transition (ref t) in
  reacs.transitions <- TransitionsSet.add t reacs.transitions;

  Reaction.add_reac_to_active_md rt amd;
  
  reacs.total_transitions_rate <-
    t.rate +. reacs.total_transitions_rate
  
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


  Log.info (fun m -> m "picking next reaction in\n 
                        Grabs:\n%s\n
                        AGrabs:\n%s\n
                        Transitions:\n%s"
                       (GrabsSet.show reacs.grabs)
                       (AGrabsSet.show reacs.agrabs)
                       (TransitionsSet.show reacs.transitions));
  

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
    Some (Grab (ref (
        (aux bound 0.
             Reaction.grab_rate_aux
             (GrabsSet.elements reacs.grabs)))))
  else if bound <  reacs.total_grabs_rate
                   +. reacs.total_agrabs_rate
  then
    let a0 = reacs.total_agrabs_rate
    and r = Random.float 1. in
    let bound = r *. a0 in
    Some
      (AGrab (ref (aux bound 0.
           Reaction.agrab_rate_aux
           (AGrabsSet.elements reacs.agrabs))))
  else
    let a0 = reacs.total_transitions_rate
    and r = Random.float 1. in
    let bound = r *. a0 in
    Some( Transition (
      ref (aux bound 0.
           Reaction.transition_rate_aux
           (TransitionsSet.elements reacs.transitions))))

let rec update_reaction_rates (reac : Reaction.t) reac_mgr=
  match reac with
  | Grab g -> update_grab_rate g reac_mgr
  | AGrab ag -> update_agrab_rate ag reac_mgr
  (*  | Self_grab sg -> update_self_grab_rate sg reac_mgr *)
  | Transition t -> update_transition_rate t reac_mgr


 *)
