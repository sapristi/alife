

open Logs
open Batteries
open Reaction
   
let src = Logs.Src.create "reactions" ~doc:"logs reacs events"
module Log = (val Logs.src_log src : Logs.LOG)

(* * file overview *)
  

(* ** MakeReacsSet functor  *)
  
(*    MakeReacSet is a functor that takes a Reacs.REAC and defines : *)
  
(*    type t : a record that contains  *)
(*      + a set of reactions *)
(*      + the  current sum of the rates of the reactions  *)
(*      + a modifier field which is a parameter to tune reaction rates  *)
(*        depending on their type. *)

(*    Various wrappers around the set *)
  



(* ** Reac_mgr module *)

(*    We then define : *)

(*    + type t : a record with a field containing a ReacsSet.t for each kind of reaction *)
   
(*    + various wrappers that take a reaction as argument, unwrap them *)
(*      and dispatch them to the right ReacsSet according to their kind *)

(*    + add_kind : adds a new reaction, for each kind *)

(*    + pick_next_reaction : picks a random reaction from one of the sets *)
(*      depending on the reaction rates *)

(* ** TODO Why separate reactions *)

(*    It would be much easier to put all the reactions in the same set,  *)
(*    but by separating them we can easily dinamically tune the rate depending on *)
(*    reaction type. *)

(*    Maybe we should put the parameters directly in the reaction,  *)
(*    then we could put all the reactions in the same set, which would greatly reduce  *)
(*    boilerplate in this file, especially if the number of reactions kind grows. *)


           
(* * MakeReacSet functor *)

module MakeReacSet (Reac : Reacs.REAC) = 
  struct
    type elt = Reac.t
    module RSet= Set.Make(Reac)  
               
    type t = {mutable total_rate : float;
              mutable set : RSet.t;
              modifier : float}
    let make_empty (modifier : float) : t =
      {total_rate = 0.;
       set = RSet.empty;
       modifier;}

    let remove r s =
      let rate = Reac.rate r in
      s.set <- RSet.remove r s.set;
      s.total_rate <- s.total_rate -. rate

    let add r s =
      s.set <- RSet.add r s.set;
      s.total_rate <- s.total_rate +. (Reac.rate r)
      
    let update_rate r s =
      let rate_delta = Reac.update_rate r in
      s.total_rate <- s.total_rate +. rate_delta
      
    let show (s : t) =
      RSet.fold (fun (e : elt) desc ->
          (Reac.show e)^"\n"^desc) s.set ""
      
    let rec pick_reaction_aux (b : float) (c : float)
                          (l : Reac.t list)  = 
      match l with
      | h::t ->
         let c' = c +. Reac.rate h in
         if c' > b then h
         else pick_reaction_aux b c' t
      | [] -> failwith "pick_reaction @ reactions.ml : can't find reaction"
            
    let pick_reaction (s : t) =
      pick_reaction_aux (Random.float s.total_rate) 0.
                        (RSet.elements s.set)
      
end

module GSet = MakeReacSet(Reacs.Grab)
module TSet = MakeReacSet(Reacs.Transition)
module BSet = MakeReacSet(Reacs.Break)

(* * module defs *)

type config = { transition_rate : float;
                grab_rate : float;
                break_rate : float;}
                [@@ deriving yojson]       
type t =
  { t_set :  TSet.t;
    g_set :  GSet.t;
    b_set :  BSet.t;
  }

let make_new (config : config) =
  {t_set = TSet.make_empty config.transition_rate;
   g_set = GSet.make_empty config.grab_rate;
   b_set = BSet.make_empty config.break_rate;}
  
let remove_reactions reactions reac_mgr =
  ReacSet.iter
    (fun (r : Reaction.t) ->
      match r with
      | Transition t ->
         TSet.remove !t reac_mgr.t_set
         
      | Grab g ->
         GSet.remove !g reac_mgr.g_set;
         Reaction.unlink r;

      | Break b ->
         BSet.remove !b reac_mgr.b_set;

    ) reactions

(* **** collision *)
(*     The collision probability between two molecules is *)
(*     the product of their quantities. *)
(*     We might need to add other parameters, such as *)
(*     the volume of the container, and use a float constant *)
(*     to avoid integer overflow. *)
(*     We here calculate each collision probability, *)
(*     and the sum of it. *)
(*     WARNING : possible integer overflow  *)
(* https://fr.wikipedia.org/wiki/Th%C3%A9orie_des_collisions *)

(* ** Grabs *)

let add_grab (graber_d : Reactant.Amol.t ref)
             (grabed_d : Reactant.t ) (reac_mgr :t)  =

  Log.debug (fun m -> m "added new grab between : %s\n%s"
                        (Reactant.Amol.show !graber_d)
                        (Reactant.show grabed_d));
  
  let (g:Reacs.Grab.t) = Reacs.Grab.make (graber_d,grabed_d)   in
  GSet.add g reac_mgr.g_set;
  
  let r = Reaction.Grab (ref g) in
  Reactant.Amol.add_reac r !graber_d;
  Reactant.add_reac r grabed_d
 
  
(* ** Transitions *)
  
           
let add_transition amd reac_mgr  =
  Log.debug (fun m -> m "added new transition : %s"
                        (Reactant.Amol.show !amd));
  
  let t = Reacs.Transition.make amd   in
  TSet.add t reac_mgr.t_set;
  
  let rt = Reaction.Transition (ref t) in
  Reactant.Amol.add_reac rt !amd


(* ** BreakInert *)
let add_break md reac_mgr =
  Log.debug (fun m -> m "added new break : %s"
                        (Reactant.show md));
  
  let b = Reacs.Break.make md in
  BSet.add b reac_mgr.b_set;

  let rb = Reaction.Break (ref b) in
  Reactant.add_reac rb md


  
  
(* ** pick next reaction *)
(* replace to_list with to_enum ? *)
let pick_next_reaction (reac_mgr:t) : Reaction.t option=

  let total_g_rate = reac_mgr.g_set.total_rate
                     *. reac_mgr.g_set.modifier
  and total_t_rate = reac_mgr.t_set.total_rate
                     *. reac_mgr.t_set.modifier
  and total_b_rate = reac_mgr.b_set.total_rate
                    *. reac_mgr.b_set.modifier
  in

  

  Log.info (fun m -> m "picking next reaction in\n 
                        Grabs (total : %f):\n%s\n
                        Transitions (total : %f):\n%s\n
                        Breaks (total : %f):\n%s"
                       total_g_rate
                       (GSet.show reac_mgr.g_set)
                       total_t_rate
                       (TSet.show reac_mgr.t_set)
                       total_b_rate
                       (BSet.show reac_mgr.b_set));
  
  
  let a0 = (total_g_rate) +. (total_t_rate)
           +. (total_b_rate)
  in
  if a0 = 0.
  then
    (
      Log.info (fun m -> m "No reaction available");
      None
    )
  else
    
    let r = Random.float 1. in
    let bound = r *. a0 in
    let res = 
      if bound < total_g_rate 
      then
        Reaction.Grab (ref (GSet.pick_reaction reac_mgr.g_set))
      else if bound < total_g_rate +. total_t_rate
      then 
        Reaction.Transition ( ref (TSet.pick_reaction reac_mgr.t_set))
      else 
        Reaction.Break (ref (BSet.pick_reaction reac_mgr.b_set))
    in
    Log.info (fun m -> m "picked %s" (Reaction.show res));
    Some res

(* ** update_reaction_rates *)
    
let rec update_reaction_rates (reac : Reaction.t) reac_mgr=
  match reac with
  | Grab g -> 
     GSet.update_rate !g reac_mgr.g_set
  | Transition t -> 
     TSet.update_rate !t reac_mgr.t_set
  | Break b ->
     BSet.update_rate !b reac_mgr.b_set



(* ** too complicated stuff *)


(* ** REACSet functor *)
(*module type REACSET =
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
  end*)
    
(*
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
  type elt
  module ReacSet : REACSET with type elt = elt
  val this : ReacSet.t
  val add : elt -> unit
  val remove : elt -> unit
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
     let add e = this.set <- RS.RSet.add e this.set
     let remove e = this.set <- RS.RSet.remove e this.set
   end : ReacSetInstance)
   *)
