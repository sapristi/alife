

open Logs
open Batteries
open Reaction
   
let src = Logs.Src.create "reactions" ~doc:"logs reacs events";;
module Log = (val Logs.src_log src : Logs.LOG);;


(* * Reaction module *)

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
  
module MakeReacSet (Reac : Reactions.REAC) = 
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

module GSet = MakeReacSet(Grab)
module AGSet = MakeReacSet(AGrab)
module TSet = MakeReacSet(Transition)

(* ** too complicated stuff *)
  
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

(* ** module defs *)
            
type t =
  { t_set :  TSet.t;
    g_set :  GSet.t;
    ag_set :  AGSet.t
  }

let make_new () =
  {t_set = TSet.make_empty 1.;
   g_set = GSet.make_empty 1.;
   ag_set = AGSet.make_empty 1.;}
  
let remove_reactions reactions reac_mgr =
  ReacSet.iter
    (fun (r : Reaction.t) ->
      match r with
      | Transition t ->
         TSet.remove !t reac_mgr.t_set
         
      | Grab g ->
         GSet.remove !g reac_mgr.g_set;
         Reaction.unlink r;
         
      | AGrab ag ->
         AGSet.remove !ag reac_mgr.ag_set;
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

let add_grab (graber_d : MolData.Active.t)
             (grabed_d : MolData.Inert.t) (reac_mgr :t)  =
  let (g:Grab.t) = Grab.make (graber_d,grabed_d) 
  in

  Log.debug (fun m -> m "added new grab between : %s\n%s"
                        (MolData.Active.show graber_d)
                        (MolData.Inert.show grabed_d));
  
  let r = Reaction.Grab (ref g) in
  GSet.add g reac_mgr.g_set;
  MolData.Active.add_reac r graber_d;
  MolData.Inert.add_reac r grabed_d
  
  
(* ** AGrabs *)

  
let add_agrab (graber_d : MolData.Active.t)
              (grabed_d : MolData.Active.t) reac_mgr  =
  let (ag : AGrab.t) = AGrab.make (graber_d,grabed_d) 
  in
  
  Log.debug (fun m -> m "added new agrab between : %s\n%s"
                        (MolData.Active.show graber_d)
                        (MolData.Active.show grabed_d));
  let r = Reaction.AGrab (ref ag) in
  AGSet.add ag reac_mgr.ag_set;
  MolData.Active.add_reac r graber_d;
  MolData.Active.add_reac r grabed_d
  
(* ** Transitions *)
  
           
let add_transition amd reac_mgr  =
  let t = Transition.make amd 
  in
  Log.debug (fun m -> m "added new transition : %s"
                        (MolData.Active.show amd));
  
  let rt = Reaction.Transition (ref t) in
  TSet.add t reac_mgr.t_set;
  MolData.Active.add_reac rt amd

  
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
let pick_next_reaction (reac_mgr:t) : Reaction.t option=


  Log.info (fun m -> m "picking next reaction in\n 
                        Grabs:\n%s\n
                        AGrabs:\n%s\n
                        Transitions:\n%s"
                       (GSet.show reac_mgr.g_set)
                       (AGSet.show reac_mgr.ag_set)
                       (TSet.show reac_mgr.t_set));
  
  let total_g_rate = reac_mgr.g_set.total_rate
                     *. reac_mgr.g_set.modifier
  and total_ag_rate = reac_mgr.ag_set.total_rate
                      *. reac_mgr.ag_set.modifier
  and total_t_rate = reac_mgr.t_set.total_rate
                     *. reac_mgr.t_set.modifier
  in
  let a0 = (total_g_rate) +. (total_ag_rate) +. (total_t_rate)
  in
  if a0 = 0.
  then None
  else
    
    let r = Random.float 1. in
    let bound = r *. a0 in
    if bound < total_g_rate 
    then
      Some (Grab (ref (GSet.pick_reaction reac_mgr.g_set)))
    else if bound <  total_g_rate +. total_ag_rate
    then
      Some (AGrab (ref (AGSet.pick_reaction reac_mgr.ag_set)))
    else
      Some( Transition ( ref (TSet.pick_reaction reac_mgr.t_set)))
      
let rec update_reaction_rates (reac : Reaction.t) reac_mgr=
  match reac with
  | Grab g -> 
     GSet.update_rate !g reac_mgr.g_set
  | AGrab ag -> 
     AGSet.update_rate !ag reac_mgr.ag_set
  | Transition t -> 
     TSet.update_rate !t reac_mgr.t_set

