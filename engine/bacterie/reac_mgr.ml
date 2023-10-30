open Reaction
open Local_libs

(* open Yaac_config *)
open Easy_logging_yojson
open Local_libs.Numeric
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

let logger = Logging.get_logger "Yaac.Bact.Reac_mgr"

(* * ReacSet modules *)
(* Reaction containers *)

(* ** ReacSet module type *)
module type ReacSet = sig
  type elt
  type t

  val pp : Format.formatter -> t -> unit
  val show : t -> string
  val to_yojson : t -> Yojson.Safe.t
  val cardinal : t -> int
  val empty : unit -> t
  val total_rate : t -> Q.t
  val add : elt -> t -> unit
  val remove : Reaction.t -> t -> unit
  val update_rate : Reaction.t -> t -> unit
  val pick_reaction : t -> Reaction.t
end

(* ** MakeReacSet functor *)
(* generic container functor *)

open Numeric

module MakeReacSet (Reac : Reacs.REAC) = struct
  let logger = Logging.get_logger "Yaac.Bact.Reac_mgr.ReacSet"

  type elt = Reac.t

  module RSet = CCSet.Make (Reac)

  type t = { mutable rates_sum : Q.t; mutable set : RSet.t }

  let pp fmt s =
    if RSet.is_empty s.set then Format.fprintf fmt "ReacSet (empty)"
    else (RSet.pp ~pp_start:(Misc_library.printer "ReacSet:") Reac.pp) fmt s.set

  let show (s : t) = Format.asprintf "%a" pp s
  let cardinal r = RSet.cardinal r.set
  let empty () : t = { rates_sum = Q.zero; set = RSet.empty }
  let calculate_rate s = RSet.fold (fun e s -> Q.(s + Reac.rate e)) s.set Q.zero
  let total_rate s = s.rates_sum

  let check_reac_rates s =
    if not (Q.equal s.rates_sum (calculate_rate s)) then (
      logger#error "Stored and computed rates are not equal: %.20f != %.20f\n%s"
        (Q.to_float s.rates_sum)
        (Q.to_float (calculate_rate s))
        (show s);
      failwith
        (Printf.sprintf "error %f %f\n %s" (Q.to_float s.rates_sum)
           (Q.to_float (calculate_rate s))
           (show s)))

  let remove r s =
    logger#debug "Remove %s" (Reac.show r);

    let open Q in
    (* we first update the reaction rate
       to avoid collisions with possible
       updates of this reaction (this avoids
       checking the reaction was not removed in
       the update_rate function *)
    let rate_delta = Reac.update_rate r in
    s.rates_sum <- s.rates_sum + rate_delta;

    let rate = Reac.rate r in
    s.set <- RSet.remove r s.set;
    s.rates_sum <- s.rates_sum - rate;
    if Config.check_reac_rates then check_reac_rates s

  let add r s =
    logger#debug "Add %s" (Reac.show r);
    let open Q in
    s.set <- RSet.add r s.set;
    s.rates_sum <- s.rates_sum + Reac.rate r;
    if Config.check_reac_rates then check_reac_rates s

  let update_rate r s =
    logger#debug "Update %s" (Reac.show r);
    let open Q in
    let rate_delta = Reac.update_rate r in
    s.rates_sum <- s.rates_sum + rate_delta;
    logger#debug "rate delta: %f, new_rate: %f" (Q.to_float rate_delta)
      (Q.to_float s.rates_sum);
    if Config.check_reac_rates then check_reac_rates s

  let to_yojson s =
    `Assoc
      [
        ("total", Q.to_yojson s.rates_sum);
        ("reactions", `List (List.map Reac.to_yojson (RSet.to_list s.set)));
      ]

  let pick_reaction randstate (s : t) =
    logger#ldebug
      (lazy (Printf.sprintf "Picking new reaction from \n%s" (show s)));

    let bound = Random_s.q randstate s.rates_sum in
    try Misc_library.pick_from_list bound Q.zero Reac.rate (RSet.elements s.set)
    with Not_found ->
      logger#error "Not found with bound %s, rates_sum %s in\n%s "
        (Q.show bound) (Q.show s.rates_sum) (show s);
      raise Not_found
end

(* ** CSet : Collision Set *)
(* This module is custom made for collisions, where reactions are not stored, *)
(* but dynamically calculated from the set of reactants. *)

module CSet = struct
  let collision_factor (reactant : Reactant.t) =
    match reactant with
    | Amol amol -> Q.one
    | ImolSet imolset -> Q.of_int imolset.qtt

  module Colliders = struct
    include CCSet.Make (Reactant)

    let random_pick randstate (ccset : t) =
      let weighted_l =
        List.map (fun elem -> (collision_factor elem, elem)) (to_list ccset)
      in
      let total_weight =
        List.fold_left
          (fun sum (weight, _) ->
            let open Numeric.Q in
            sum + weight)
          Q.zero weighted_l
      in
      Random_s.pick_from_weighted_list randstate total_weight weighted_l

    (** removes either Amol, or decrease imolset qtt by or
          Used to compute reaction rates   *)
    let remove_custom (elem : Reactant.t) ccset =
      match elem with
      | Amol amol -> remove elem ccset
      | ImolSet imolset ->
          let new_elem = Reactant.ImolSet.copy imolset in
          Reactant.ImolSet.add_to_qtt (-1) new_elem;
          ccset |> remove elem |> add (ImolSet new_elem)
  end

  type elt = C

  type t = {
    mutable rates_sum : Q.t;
    mutable single_rates_sum : Q.t;
    mutable colliders : Colliders.t;
  }

  let pp fmt s =
    if Colliders.is_empty s.colliders then Format.fprintf fmt "ReacSet (empty)"
    else
      (Colliders.pp ~pp_start:(Misc_library.printer "ReacSet:") Reactant.pp)
        fmt s.colliders

  let show (s : t) = Format.asprintf "%a" pp s
  let to_yojson (s : t) = `String "CSet"
  let cardinal (s : t) = Colliders.cardinal s.colliders

  let empty () : t =
    {
      rates_sum = Q.zero;
      single_rates_sum = Q.zero;
      colliders = Colliders.empty;
    }

  (** total rate is:
        TR  = Σ_(i<j) λ_i q_i λ_j q_j + Σ_i λ_i² q_i (q_i - 1)

        we can use the identity
        (Σ_i λ_i q_i)² = 2 Σ_(i<j) λ_i q_i λ_j q_j + Σ_i (λ_i q_i)²

        we to rewrite TR as:
        TR = [ (Σ_i λ_i q_i)² - Σ_i (λ_i q_i)²]/2  + Σ_i λ_i² q_i (q_i - 1)

        where :
          - λ_i is the collision factor of a molecule
          - q_i is the quantity of a molecule
     *)
  let calculate_rate (s : t) =
    let open Q in
    let rate_t_qtt a = collision_factor a * of_int (Reactant.qtt a) in
    let single_rates_sum =
      Colliders.fold
        (fun (a : Reactant.t) b -> rate_t_qtt a + b)
        s.colliders zero
    and square_rates_sum =
      Colliders.fold
        (fun (a : Reactant.t) b -> (rate_t_qtt a * rate_t_qtt a) + b)
        s.colliders zero
    in
    (((single_rates_sum * single_rates_sum) - square_rates_sum) / (one + one))
    + Colliders.fold
        (fun (a : Reactant.t) b ->
          (collision_factor a * of_int (Reactant.qtt a) * rate_t_qtt a) + b)
        s.colliders zero

  let total_rate s = s.rates_sum

  let check_reac_rate (s : t) =
    if not (Q.equal s.rates_sum (calculate_rate s)) then (
      logger#error "Stored and computed rates are not equal: %.20f != %.20f\n%s"
        (Q.to_float s.rates_sum)
        (Q.to_float (calculate_rate s))
        (show s)
      |> ignore;
      failwith
        (Printf.sprintf "error %f %f\n %s" (Q.to_float s.rates_sum)
           (Q.to_float (calculate_rate s))
           (show s)))

  let add r (s : t) =
    let open Q in
    let cf = collision_factor r in
    s.colliders <- Colliders.add r s.colliders;
    s.rates_sum <- s.rates_sum + (cf * (cf - one)) + (cf * s.single_rates_sum);
    s.single_rates_sum <- s.single_rates_sum + cf

  let remove c (s : t) =
    let open Q in
    let r1, r2 = Reacs.Collision.get_reactants c in

    let cf = collision_factor r1 in
    s.single_rates_sum <- s.single_rates_sum - cf;
    s.rates_sum <- s.rates_sum - (cf * (cf - one)) - (cf * s.single_rates_sum);
    s.colliders <- Colliders.remove r1 s.colliders

  let update_rate r (s : t) = logger#trace "Update rate" |> ignore

  (** TODO FIX Colliders.choose *)
  let pick_reaction randstate (s : t) =
    let c1 = Colliders.random_pick randstate s.colliders in
    let colliders' = Colliders.remove_custom c1 s.colliders in
    let c2 = Colliders.random_pick randstate colliders' in
    let c = Reacs.Collision.make (c1, c2) in
    logger#debug "Picked %s and %s from %s" (Reactant.show c1)
      (Reactant.show c2)
      (Format.asprintf "%a" (Colliders.pp Reactant.pp) s.colliders);
    c
end

module GSet = MakeReacSet (Reacs.Grab)
module TSet = MakeReacSet (Reacs.Transition)
module BSet = MakeReacSet (Reacs.Break)

(* * Main  defs *)

type t = {
  t_set : TSet.t;
  g_set : GSet.t;
  b_set : BSet.t;
  c_set : CSet.t;
  mutable reac_counter : int;
  env : Environment.t ref;
}
[@@deriving show]

let tag (rmgr : t) : string =
  let open Q in
  let total_g_rate = !(rmgr.env).grab_rate * GSet.total_rate rmgr.g_set
  and total_t_rate = !(rmgr.env).transition_rate * TSet.total_rate rmgr.t_set
  and total_b_rate = !(rmgr.env).break_rate * BSet.total_rate rmgr.b_set
  and total_c_rate = !(rmgr.env).collision_rate * CSet.total_rate rmgr.c_set in
  Printf.sprintf "%i,(G: %s, T: %s, B: %s, C: %s)" rmgr.reac_counter
    (Q.show total_g_rate) (Q.show total_t_rate)
    (string_of_float @@ Q.to_float total_b_rate)
    (Q.show total_c_rate)

let get_available_reac_nb rmgr =
  (TSet.cardinal rmgr.t_set, GSet.cardinal rmgr.g_set, BSet.cardinal rmgr.b_set)

let to_yojson (rmgr : t) : Yojson.Safe.t =
  `Assoc
    [
      ("transitions", TSet.to_yojson rmgr.t_set);
      ("grabs", GSet.to_yojson rmgr.g_set);
      ("breaks", BSet.to_yojson rmgr.b_set);
      ("reac_counter", `Int rmgr.reac_counter);
      ("env", Environment.to_yojson !(rmgr.env));
    ]

let make_new (env : Environment.t ref) =
  {
    t_set = TSet.empty ();
    g_set = GSet.empty ();
    b_set = BSet.empty ();
    c_set = CSet.empty ();
    reac_counter = 0;
    env;
  }

let remove_reactions reactions reac_mgr =
  ReacSet.iter
    (fun (r : Reaction.t) ->
      match r with
      | Transition t -> TSet.remove t reac_mgr.t_set
      | Grab g ->
          GSet.remove g reac_mgr.g_set;
          Reaction.unlink r
      | Break b -> BSet.remove b reac_mgr.b_set
      | Collision c -> CSet.remove c reac_mgr.c_set)
    reactions

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

let add_grab (graber_d : Reactant.Amol.t) (grabed_d : Reactant.t) (reac_mgr : t)
    =
  (* Log.debug (fun m -> m "added new grab between : %s\n%s"
   *                       (Reactant.Amol.show !graber_d)
   *                       (Reactant.show grabed_d)); *)
  logger#trace
    ~tags:[ tag reac_mgr ]
    "adding new grab between : \n- %s\n- %s"
    (Reactant.Amol.show graber_d)
    (Reactant.show grabed_d);

  let (g : Reacs.Grab.t) = Reacs.Grab.make (graber_d, grabed_d) in
  GSet.add g reac_mgr.g_set;

  let r = Reaction.Grab g in
  Reactant.Amol.add_reac r graber_d;
  Reactant.add_reac r grabed_d

(* ** Transitions *)

let add_transition amd reac_mgr =
  logger#trace
    ~tags:[ tag reac_mgr ]
    "adding new transition : %s" (Reactant.Amol.show amd);

  let t = Reacs.Transition.make amd in
  TSet.add t reac_mgr.t_set;

  let rt = Reaction.Transition t in
  Reactant.Amol.add_reac rt amd

(* ** Break *)
let add_break md reac_mgr =
  logger#trace ~tags:[ tag reac_mgr ] "adding new break : %s" (Reactant.show md);

  let b = Reacs.Break.make md in
  BSet.add b reac_mgr.b_set;

  let rb = Reaction.Break b in
  Reactant.add_reac rb md

let add_collider md reac_mgr =
  logger#trace
    ~tags:[ tag reac_mgr ]
    "adding new collider : %s" (Reactant.show md);

  CSet.add md reac_mgr.c_set;

  let collider = Reacs.Collision.make (md, Dummy) in
  let collider_reac = Reaction.Collision collider in
  Reactant.add_reac collider_reac md

(* let rc = Reaction.Collision  in
   Reactant.add_reac rc md; *)

(* ** pick next reaction *)
(* replace to_list with to_enum ? *)
let pick_next_reaction randstate (reac_mgr : t) : Reaction.t option =
  let open Q in
  let total_g_rate = !(reac_mgr.env).grab_rate * GSet.total_rate reac_mgr.g_set
  and total_t_rate =
    !(reac_mgr.env).transition_rate * TSet.total_rate reac_mgr.t_set
  and total_b_rate = !(reac_mgr.env).break_rate * BSet.total_rate reac_mgr.b_set
  and total_c_rate =
    !(reac_mgr.env).collision_rate * CSet.total_rate reac_mgr.c_set
  in

  logger#ldebug
    (lazy
      (Printf.sprintf
         "********     Grabs   (total rate: %s)  (nb_reacs: %d)  *********\n%s"
         (Q.show total_g_rate)
         (GSet.cardinal reac_mgr.g_set)
         (GSet.show reac_mgr.g_set)));

  logger#ldebug
    (lazy
      (Printf.sprintf
         "******** Transitions (total rate: %s)  (nb_reacs: %d)  *********\n%s"
         (Q.show total_t_rate)
         (TSet.cardinal reac_mgr.t_set)
         (TSet.show reac_mgr.t_set)));

  logger#ldebug
    (lazy
      (Printf.sprintf
         "********    Breaks   (total rate: %s)  (nb_reacs: %d)  *********\n%s"
         (Q.show total_b_rate)
         (BSet.cardinal reac_mgr.b_set)
         (BSet.show reac_mgr.b_set)));

  logger#ldebug
    (lazy
      (Printf.sprintf
         "********    Collision   (total rate: %s)  (nb_reacs: %d)  *********\n\
          %s"
         (Q.show total_c_rate)
         (CSet.cardinal reac_mgr.c_set)
         (CSet.show reac_mgr.c_set)));

  let a0 = total_g_rate + total_t_rate + total_b_rate + total_c_rate in
  if a0 = Q.zero then (
    logger#warning ~tags:[ tag reac_mgr ] "No reaction available";
    None)
  else (
    reac_mgr.reac_counter <- Pervasives.(reac_mgr.reac_counter + 1);
    let bound = Random_s.q randstate a0 in
    logger#debug ~tags:[ tag reac_mgr ] "Picked bound %s" (Q.show bound);
    let res =
      if lt bound total_g_rate then
        Reaction.Grab (GSet.pick_reaction randstate reac_mgr.g_set)
      else if lt bound (total_g_rate + total_t_rate) then
        Reaction.Transition (TSet.pick_reaction randstate reac_mgr.t_set)
      else if lt bound (total_g_rate + total_t_rate + total_b_rate) then
        Reaction.Break (BSet.pick_reaction randstate reac_mgr.b_set)
      else Reaction.Collision (CSet.pick_reaction randstate reac_mgr.c_set)
    in
    logger#info ~tags:[ tag reac_mgr ] "picked %s" (Reaction.show res);
    Some res)

(* ** update_reaction_rates *)

let rec update_reaction_rate (reac : Reaction.t) reac_mgr =
  match reac with
  | Grab g -> GSet.update_rate g reac_mgr.g_set
  | Transition t -> TSet.update_rate t reac_mgr.t_set
  | Break b -> BSet.update_rate b reac_mgr.b_set
  | Collision c -> CSet.update_rate c reac_mgr.c_set

let update_rates (reactions : ReacSet.t) reac_mgr =
  ReacSet.iter (fun reac -> update_reaction_rate reac reac_mgr) reactions

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
(* for binding reactions ? *)
module MakeAutoUpdatingReacSet (Reac : Reacs.REAC) = struct
  type elt = Reac.t

  module RSet = Set.Make (Reac)

  type t = { mutable total_rate : Q.t; mutable set : RSet.t }

  let make_empty () : t = { total_rate = Q.zero; set = RSet.empty }
  let remove r s = s.set <- RSet.remove r s.set
  let add r s = s.set <- RSet.add r s.set
  let update_rate r s = ()

  let total_rate s =
    s.total_rate <- RSet.fold (fun r res -> Q.(Reac.rate r + res)) s.set Q.zero;
    s.total_rate

  let show (s : t) =
    RSet.fold (fun (e : elt) desc -> Reac.show e ^ "\n" ^ desc) s.set ""

  let pick_reaction randstate (s : t) =
    Misc_library.pick_from_list
      (Random_s.q randstate s.total_rate)
      Q.zero Reac.rate (RSet.elements s.set)
end
