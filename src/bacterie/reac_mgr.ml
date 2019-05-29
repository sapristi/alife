open Reaction
open Local_libs
open Yaac_config
open Easy_logging_yojson

open Local_libs.Numeric.Num
(* * file overview *)
  

(* ** MakeReacsSet functor  *)
  
(*    MakeReacSet is a functor that takes a Reacs.REAC and defines : *)
  
(*    type t : a record that contains  *)
(*      + a set of reactions *)
(*      + the  current sum of the rates of the reactions  *)

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


let logger = Logging.get_logger "Yaac.Bact.Reacs.reacs_mgr"
               
(* * MakeReacSet functor *)
open Numeric
module MakeReacSet
         (Reac : Reacs.REAC)
  = 
  struct
    let logger = Logging.get_logger "Yaac.Bact.Reacs.ReacSet"
    type elt = Reac.t
    module RSet= CCSet.Make(Reac)  
               
    type t = {mutable rates_sum : num;
              mutable set : RSet.t;}

    let pp fmt e =
      (RSet.pp ~start:"ReacSet" Reac.pp) fmt e.set
            
    let show (s : t) =
      Format.asprintf "%a" pp s

    let cardinal r = RSet.cardinal r.set
    let empty () : t =
      {rates_sum = zero;
       set = RSet.empty;}
    let calculate_rate s =
      RSet.fold (fun e s ->
          s + Reac.rate e) s.set zero
    let total_rate s =
      s.rates_sum

    let check_reac_rates s =
      if  not (Num.equal s.rates_sum (calculate_rate s))
      then
        begin
          logger#error "Stored and computed rates are not equal: %.20f != %.20f\n%s"
            (float_of_num s.rates_sum)
            (float_of_num (calculate_rate s))
            (show s);
          failwith (Printf.sprintf "error %f %f\n %s"
                      (float_of_num s.rates_sum)
                      (float_of_num (calculate_rate s))
                      (show s))
        end
      
    let remove r s =
      logger#debug "Remove %s" (Reac.show r);

      (* we first update the reaction rate 
         to avoid collisions with possible 
         updates of this reaction (this avoids
         checking the reaction was not removed in
         the update_rate function   *)
      let rate_delta = Reac.update_rate r in
      s.rates_sum <- s.rates_sum + rate_delta;
      
      let rate = Reac.rate r in
      s.set <- RSet.remove r s.set;
      s.rates_sum <- s.rates_sum - rate;
      if Config.check_reac_rates
      then check_reac_rates s
             
    let add r s =

      logger#debug  "Add %s" (Reac.show r);

      s.set <- RSet.add r s.set;
      s.rates_sum <- s.rates_sum + (Reac.rate r);
      if Config.check_reac_rates
      then check_reac_rates s
      
    let update_rate r s =

      logger#debug "Update %s" (Reac.show r);

      let rate_delta = Reac.update_rate r in
      s.rates_sum <- s.rates_sum + rate_delta;
      logger#debug "rate delta: %f, new_rate: %f"
        (float_of_num rate_delta)
        (float_of_num s.rates_sum);
      if Config.check_reac_rates
      then check_reac_rates s


    let to_yojson s =
      `Assoc [
          "total", num_to_yojson s.rates_sum;
          "reactions", `List (List.map Reac.to_yojson (RSet.to_list s.set)) ]
    let pick_reaction (s : t) =
      logger#ldebug (lazy(Printf.sprintf "Picking new reaction from \n%s"
      (show s)));
      
      let bound = random s.rates_sum in
      try
        Misc_library.pick_from_list bound zero
          Reac.rate
          (RSet.elements s.set)
      with
        Not_found ->
        logger#error "Not found with bound %s, rates_sum %s in\n%s "
          (show_num bound) (show_num s.rates_sum)
          (show s);
        raise Not_found
end
(* for binding reactions ? *)
module MakeAutoUpdatingReacSet (Reac : Reacs.REAC) = 
  struct
    type elt = Reac.t
    module RSet= Set.Make(Reac)  
               
    type t = {mutable total_rate : num;
              mutable set : RSet.t;}
    let make_empty () : t =
      {total_rate = zero; set = RSet.empty;}
      
    let remove r s = s.set <- RSet.remove r s.set
    let add r s = s.set <- RSet.add r s.set
    let update_rate r s = ()
    let total_rate s =
      s.total_rate <-
        RSet.fold
        (fun r res -> Reac.rate r + res)
        s.set zero;
      s.total_rate
      
    let show (s : t) =
      RSet.fold (fun (e : elt) desc ->
          (Reac.show e)^"\n"^desc) s.set ""
      
    let pick_reaction (s : t) =
      Misc_library.pick_from_list (random s.total_rate) zero
                                  Reac.rate
                                  (RSet.elements s.set)
      
end
module GSet = MakeReacSet(Reacs.Grab)
module TSet = MakeReacSet(Reacs.Transition)
module BSet = MakeReacSet(Reacs.Break)




(* * module defs *)


type t =
  { t_set :  TSet.t;
    g_set :  GSet.t;
    b_set :  BSet.t;
    mutable reac_counter : int;
    env : Environment.t ref; 
  }
    [@@deriving show]

let tag (rmgr:t) : string =
  let total_g_rate =
    !(rmgr.env).grab_rate *
      GSet.total_rate rmgr.g_set
  and total_t_rate = 
    !(rmgr.env).transition_rate *
      TSet.total_rate rmgr.t_set
  and total_b_rate = 
    !(rmgr.env).break_rate *
      BSet.total_rate rmgr.b_set
  in
  Printf.sprintf "%i,(G: %s, T: %s, B: %s)"
    rmgr.reac_counter
    (Num.show_num total_g_rate)
    (Num.show_num total_t_rate)
    (string_of_float @@ Num.float_of_num total_b_rate)
   
           
let get_available_reac_nb rmgr =
  (TSet.cardinal rmgr.t_set, GSet.cardinal rmgr.g_set,
   BSet.cardinal rmgr.b_set)
  
let to_yojson (rmgr : t) : Yojson.Safe.json =
  `Assoc [
      "transitions", TSet.to_yojson rmgr.t_set;
      "grabs", GSet.to_yojson rmgr.g_set;
      "breaks", BSet.to_yojson rmgr.b_set;
      "reac_counter", `Int rmgr.reac_counter;
      "env", Environment.to_yojson !(rmgr.env)]

  
let make_new (env : Environment.t ref) = 
  {t_set = TSet.empty ();
   g_set = GSet.empty ();
   b_set = BSet.empty ();
   reac_counter = 0;
   env = env; } 


  
let remove_reactions reactions reac_mgr =
  ReacSet.iter
    (fun (r : Reaction.t) ->
      match r with
      | Transition t ->
         TSet.remove t reac_mgr.t_set
         
      | Grab g ->
         GSet.remove g reac_mgr.g_set;
         Reaction.unlink r;

      | Break b ->
         BSet.remove b reac_mgr.b_set;

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

let add_grab (graber_d : Reactant.Amol.t)
             (grabed_d : Reactant.t ) (reac_mgr :t)  =


  (* Log.debug (fun m -> m "added new grab between : %s\n%s"
   *                       (Reactant.Amol.show !graber_d)
   *                       (Reactant.show grabed_d)); *)
  
  
  logger#trace ~tags:([tag reac_mgr]) "adding new grab between : \n- %s\n- %s"
                    (Reactant.Amol.show graber_d)
                    (Reactant.show grabed_d);

  let (g:Reacs.Grab.t) = Reacs.Grab.make (graber_d,grabed_d)   in
  GSet.add g reac_mgr.g_set;
  
  let r = Reaction.Grab g in
  Reactant.Amol.add_reac r graber_d;
  Reactant.add_reac r grabed_d
  
  
(* ** Transitions *)
  
           
let add_transition amd reac_mgr  =
  logger#trace  ~tags:([tag reac_mgr])  "adding new transition : %s"
    (Reactant.Amol.show amd);
  
  let t = Reacs.Transition.make amd   in
  TSet.add t reac_mgr.t_set;
  
  let rt = Reaction.Transition t in
  Reactant.Amol.add_reac rt amd


(* ** Break *)
let add_break md reac_mgr =
  logger#trace  ~tags:([tag reac_mgr]) "adding new break : %s"  (Reactant.show md);
  
  let b = Reacs.Break.make md in
  BSet.add b reac_mgr.b_set;

  let rb = Reaction.Break b in
  Reactant.add_reac rb md

  
let logger = Logging.get_logger "Yaac.Bact.Reacs.reacs_mgr"
                 
(* ** pick next reaction *)
(* replace to_list with to_enum ? *)
let pick_next_reaction (reac_mgr:t) : Reaction.t option=

  let total_g_rate =
    !(reac_mgr.env).grab_rate *
      GSet.total_rate reac_mgr.g_set
  and total_t_rate = 
    !(reac_mgr.env).transition_rate *
      TSet.total_rate reac_mgr.t_set
  and total_b_rate = 
    !(reac_mgr.env).break_rate *
      BSet.total_rate reac_mgr.b_set
  in
    
  logger#debug  "********     Grabs   (total : %s)  (nb_reacs : %d)  *********"
    (show_num total_g_rate) (GSet.cardinal reac_mgr.g_set);
  logger#ldebug (lazy (GSet.show reac_mgr.g_set));
  
  logger#debug  "******** Transitions (total : %s)  (nb_reacs : %d)  *********"
       (show_num total_t_rate) (TSet.cardinal reac_mgr.t_set);
  logger#ldebug (lazy (TSet.show reac_mgr.t_set));
  
  logger#debug  "********    Breaks   (total : %s)  (nb_reacs : %d)  *********"
       (show_num total_b_rate) (BSet.cardinal reac_mgr.b_set);
  logger#ldebug (lazy (BSet.show reac_mgr.b_set));

                     
  let a0 = (total_g_rate) + (total_t_rate)
           + (total_b_rate)
  in
  if a0 = zero
  then
    (
      logger#warning ~tags:([tag reac_mgr]) "No reaction available";
      None
    )
  else
    (
      reac_mgr.reac_counter <- Pervasives.(reac_mgr.reac_counter + 1);
      let bound = random a0 in
      logger#debug   ~tags:([tag reac_mgr]) "Picked bound %s" (Num.show_num bound);
      let res = 
        if lt bound total_g_rate 
        then
          Reaction.Grab (GSet.pick_reaction reac_mgr.g_set)
        else if lt bound (total_g_rate + total_t_rate)
        then 
          Reaction.Transition (TSet.pick_reaction reac_mgr.t_set)
        else 
          Reaction.Break (BSet.pick_reaction reac_mgr.b_set)
        
      in
      logger#info ~tags:([tag reac_mgr]) "picked %s"  (Reaction.show res);
      
      Some res
    )
    
(* ** update_reaction_rates *)
    
let rec update_reaction_rate (reac : Reaction.t) reac_mgr=
  match reac with
  | Grab g -> 
     GSet.update_rate g reac_mgr.g_set
  | Transition t -> 
     TSet.update_rate t reac_mgr.t_set
  | Break b ->
     BSet.update_rate b reac_mgr.b_set


    
let update_rates (reactions : ReacSet.t) reac_mgr =
  ReacSet.iter
    (fun reac ->
      update_reaction_rate reac reac_mgr)
    reactions


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
