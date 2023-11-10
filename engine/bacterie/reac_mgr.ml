open Reaction
open Local_libs
open Numeric

(* open Yaac_config *)
open Local_libs
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

let logger = Alog.make_logger "Yaac.Bact.Reac_mgr"


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



(** MakeReacSet functor
    generic container functor *)
module MakeReacSet (Reac : Reacs.REAC) = struct
  let logger = Alog.make_logger ("Yaac.Bact.Reac_mgr."^Reac.name)

  type elt = Reac.t

  module RSet = Local_libs.Set.Make (Reac)

  type t = { mutable rates_sum : Q.t; mutable set : RSet.t } [@@deriving eq, to_yojson]

  let pp fmt s =
    if RSet.is_empty s.set then Format.fprintf fmt "ReacSet (empty) (rate: %f)" (Q.to_float s.rates_sum)
    else
      Format.fprintf fmt "ReacSet:\n%a\n(rate: %f)"
        (RSet.pp Reac.pp) s.set
        (Q.to_float s.rates_sum)


  let show (s : t) = Format.asprintf "%a" pp s
  let cardinal r = RSet.cardinal r.set
  let empty () : t = { rates_sum = Q.zero; set = RSet.empty }
  let calculate_rate s = RSet.fold (fun e s -> Q.(s + Reac.rate e)) s.set Q.zero
  let total_rate s = s.rates_sum

  let check_reac_rates s =
    if not (Q.equal s.rates_sum (calculate_rate s)) then (

      logger.error ~tags:["stored", Q.to_yojson s.rates_sum;
                          "computed", Q.to_yojson (calculate_rate s);
                          "reac set", to_yojson s
                         ] "Rate error";
      failwith
        (Printf.sprintf "error %f %f\n %s" (Q.to_float s.rates_sum)
           (Q.to_float (calculate_rate s))
           (show s)))

  let remove r s =
    logger.debug ~tags:["reac", Reac.to_yojson r] "Remove";

    let open Q in
    (* we first update the reaction rate to avoid collisions with possible
       updates of this reaction (this avoids checking the reaction was not removed in
       the update_rate function *)
    let rate_delta = Reac.update_rate r in
    s.rates_sum <- s.rates_sum + rate_delta;

    let rate = Reac.rate r in
    s.set <- RSet.remove r s.set;
    s.rates_sum <- s.rates_sum - rate;
    if Config.check_reac_rates then check_reac_rates s

  let add r s =
    logger.debug ~tags:["reac", Reac.to_yojson r] "Add";
    let open Q in
    s.set <- RSet.add r s.set;
    s.rates_sum <- s.rates_sum + Reac.rate r;
    if Config.check_reac_rates then check_reac_rates s

  let update_rate r s =
    logger.debug ~tags:["reac", Reac.to_yojson r] "Update";
    let open Q in
    let rate_delta = Reac.update_rate r in
    s.rates_sum <- s.rates_sum + rate_delta;
    logger.debug ~tags:["delta", Q.to_yojson rate_delta; "new", Q.to_yojson s.rates_sum] "new rate";
    if Config.check_reac_rates then check_reac_rates s

  let to_yojson s =
    `Assoc
      [
        ("total", Q.to_yojson s.rates_sum);
        ("reactions", `List (List.map Reac.to_yojson (RSet.to_list s.set)));
      ]

  let pick_reaction randstate (s : t) =
    logger.debug ~ltags:(lazy ["reac set", to_yojson s]) "Picking new reaction";

    let bound = Random_s.q randstate s.rates_sum in
    try Misc_library.pick_from_list bound Q.zero Reac.rate (RSet.elements s.set)
    with Not_found ->
      logger.error ~tags:["bound", Q.to_yojson bound; "rates sum", Q.to_yojson s.rates_sum;
                         "reacs set", to_yojson s] "Not found";
      raise Not_found

  let print_debug s =
    Printf.sprintf
      "********     %ss   (total rate: %s) (comp. rate: %s) (nb_reacs: %d)  *********\n%s"
      Reac.name
      (s |> total_rate |> Q.show)
      (s |> calculate_rate |> Q.show)
      (RSet.cardinal s.set)
      (show s)

end

(** CSet : Collision Set
    This module is custom made for collisions, where reactions are not stored,
    but dynamically calculated from the set of reactants.
    We only keep the reaction rate

     We might need to add other parameters, such as
     the volume of the container.
     WARNING : possible integer overflow TODO: check
   https://fr.wikipedia.org/wiki/Th%C3%A9orie_des_collisions 
*)
module CSet = struct

  (** Collision factor - this is constant for now *)
  let collision_factor (reactant : Reactant.t) =
    match reactant with
    | Dummy -> failwith "dummy"
    | Amol amol -> Q.one
    | ImolSet imolset -> Q.one

  let collision_rate (reactant : Reactant.t) =
    match reactant with
    | Dummy -> failwith "dummy"
    | _ -> Q.(of_int (Reactant.qtt reactant) * (collision_factor reactant))

  module Colliders = struct
    include Local_libs.Set.Make (Reactant)

    let pp_orig = pp
    let pp = pp_orig Reactant.pp

    let random_pick randstate (ccset : t) =
      let weighted_l =
        List.map (fun elem -> (collision_rate elem, elem)) (to_list ccset)
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
      | Dummy -> failwith "dummy"
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
  [@@deriving eq, show]

  let to_yojson (s : t) = `String "CSet"
  let cardinal (s : t) = Colliders.cardinal s.colliders
  let empty () : t =
    {
      rates_sum = Q.zero;
      single_rates_sum = Q.zero;
      colliders = Colliders.empty;
    }

  (** Total Collision rate computation:

    Lets define
     - λᵢ is the collision factor of a molecule
     - qᵢ is the quantity of a molecule
     - γᵢ the collision rate : γᵢ = λᵢ * qᵢ

     The total rate is
        TR = Σ_(i<j) λᵢqᵢ λⱼqⱼ + Σᵢ λᵢ² qᵢ(qᵢ - 1)
        TR = Σ_(i<j) γᵢγⱼ + Σᵢ γᵢ (γᵢ - λᵢ)

      In order to quickly compute an update of the total rate,
        we can use the identity
        (Σᵢ γᵢ)² = 2 Σ_(i<j) γᵢ γⱼ + Σᵢ γᵢ²

      to rewrite TR as:
        TRₙ = [ (Σᵢⁿ γᵢ)² - Σᵢⁿ γᵢ² ]/2  + Σᵢⁿ γᵢ(γᵢ - λᵢ)

     We thus have the update formulas:
      * TRₙ₊₁ = TRₙ   + γₙ₊₁SRₙ + λₙ₊₁²qₙ₊₁(qₙ₊₁ - 1)  (when we add a molecule / qtt)
      * TRₙ   = TRₙ₊₁ - γₙ₊₁SRₙ - λₙ₊₁²qₙ₊₁(qₙ₊₁ - 1)  (when we remove a molecule / qtt)
              = TRₙ₊₁ - γₙ₊₁SRₙ₊₁ + γₙ₊₁λₙ₊₁           (when we remove a molecule / qtt - another identity)

     With SRₙ = Σᵢⁿ γᵢ

      When changing the quantity, an easy thing to do is remove the old one and add a new one
      TODO:
      - Clarify implem where we mix up collision factor and quantity
        (probably ok but would be better with another word than collision factor)


     *)
  let calculate_rates_aux (s : t) =
    let open Q in
    let single_rates_sum =
      Colliders.fold
        (fun (a : Reactant.t) b -> collision_rate a + b)
        s.colliders zero
    and square_rates_sum =
      Colliders.fold
        (fun (a : Reactant.t) b -> (collision_rate a * collision_rate a) + b)
        s.colliders zero
    in
    let total_rate =
      (((single_rates_sum * single_rates_sum) - square_rates_sum) / (one + one))
      + Colliders.fold
          (fun (a : Reactant.t) b ->
            (collision_rate a * (collision_rate a - collision_factor a)) + b)
          s.colliders zero
    in
    (single_rates_sum, total_rate)

  let calculate_rate (s : t) =
    let _, total_rate = calculate_rates_aux s in
    total_rate

  let total_rate s = s.rates_sum

  let check_reac_rates (s : t) =
    if not (Q.equal s.rates_sum (calculate_rate s)) then (
      logger.error ~tags:["stored", Q.to_yojson s.rates_sum;
                          "computed", Q.to_yojson (calculate_rate s);
                          "reac set", to_yojson s
                         ] "Rate error";
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
    (* TODO: why is single rates sum updated before here, but after in add ?? *)
    (* TODO: why do we consider only a single reactant ?? *)
    s.single_rates_sum <- s.single_rates_sum - cf;
    s.rates_sum <- s.rates_sum - (cf * (cf - one)) - (cf * s.single_rates_sum);
    s.colliders <- Colliders.remove r1 s.colliders

  (** TODO: use identities to update instead of re-computing.
      We must be careful to update each time a quantity change
  *)
  let update_rate r (s : t) =
    let single_rates_sum, total_rate = calculate_rates_aux s in
    s.rates_sum <- total_rate;
    s.single_rates_sum <- single_rates_sum

  let pick_reaction randstate (s : t) =
    let c1 = Colliders.random_pick randstate s.colliders in
    let colliders' = Colliders.remove_custom c1 s.colliders in
    let c2 = Colliders.random_pick randstate colliders' in
    let c = Reacs.Collision.make (c1, c2) in
    logger.debug ~tags:["reactants", [%to_yojson:Reactant.t list] [c1;c2];
                        "colliders", Colliders.to_yojson s.colliders] "Picked colliders";
    c

    let print_debug s =
      Printf.sprintf
        "********     Collisions   (total rate: %s) (comp. rate: %s)  *********\n%s"
        (s |> total_rate |> Q.show)
        (s |> calculate_rate |> Q.show)
        (show s)

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
  mutable reac_counter : int; [@equal fun a b -> true]
  (* for tests - we do not care about reac counter - should we serialize it instead ? *)
  env : Environment.t ref; [@equal fun a b -> true] [@opaque]
}
[@@deriving show, eq]


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

let add_grab (graber_d : Reactant.Amol.t) (grabed_d : Reactant.t) (reac_mgr : t) =
  logger.debug ~ltags:(lazy ["graber", (Reactant.Amol.to_yojson graber_d);
                      "grabed", Reactant.to_yojson grabed_d]) "adding new grab";
  let (g : Reacs.Grab.t) = Reacs.Grab.make (graber_d, grabed_d) in
  GSet.add g reac_mgr.g_set;

  let r = Reaction.Grab g in
  Reactant.Amol.add_reac r graber_d;
  Reactant.add_reac r grabed_d

let add_transition amd reac_mgr =
  logger.debug ~tags:["amol", Reactant.Amol.to_yojson amd] "adding new transition";

  let t = Reacs.Transition.make amd in
  TSet.add t reac_mgr.t_set;

  let rt = Reaction.Transition t in
  Reactant.Amol.add_reac rt amd

let add_break md reac_mgr =
  logger.debug ~tags:["mol", Reactant.to_yojson md] "adding new break";

  let b = Reacs.Break.make md in
  BSet.add b reac_mgr.b_set;

  let rb = Reaction.Break b in
  Reactant.add_reac rb md

let add_collider md reac_mgr =
  logger.debug ~tags:["mol", Reactant.to_yojson md] "adding new collider";

  CSet.add md reac_mgr.c_set;

  let collider = Reacs.Collision.make (md, Dummy) in
  let collider_reac = Reaction.Collision collider in
  Reactant.add_reac collider_reac md

(* let rc = Reaction.Collision  in
   Reactant.add_reac rc md; *)

let check_reac_rates reac_mrg =
  TSet.check_reac_rates reac_mrg.t_set;
  GSet.check_reac_rates reac_mrg.g_set;
  BSet.check_reac_rates reac_mrg.b_set;
  CSet.check_reac_rates reac_mrg.c_set

(** pick next reaction *)
(* TODO: replace to_list with to_enum ? *)
let pick_next_reaction randstate (reac_mgr : t) : Reaction.t option =
  logger.debug ~ltags:(lazy ["reacs", to_yojson reac_mgr]) "Next reaction";

  let total_g_rate =Q.( !(reac_mgr.env).grab_rate * GSet.total_rate reac_mgr.g_set)
  and total_t_rate =
    Q.( !(reac_mgr.env).transition_rate * TSet.total_rate reac_mgr.t_set )
  and total_b_rate = Q.( !(reac_mgr.env).break_rate * BSet.total_rate reac_mgr.b_set )
  and total_c_rate =
    Q.( !(reac_mgr.env).collision_rate * CSet.total_rate reac_mgr.c_set )
  in let a0 = Q.(  total_g_rate + total_t_rate + total_b_rate + total_c_rate )
  in
  if a0 = Q.zero then (
    logger.warning ~tags:["reacs", to_yojson reac_mgr] "No reaction available";
    None)
  else (
    reac_mgr.reac_counter <- Stdlib.(reac_mgr.reac_counter + 1);
    let bound = Random_s.q randstate a0 in
    logger.debug ~tags:["bound", Q.to_yojson bound ] "Picked bound";
    let res =
      if Q.lt bound total_g_rate then
        Reaction.Grab (GSet.pick_reaction randstate reac_mgr.g_set)
      else if Q.( lt bound (total_g_rate + total_t_rate) ) then
        Reaction.Transition (TSet.pick_reaction randstate reac_mgr.t_set)
      else if Q.( lt bound (total_g_rate + total_t_rate + total_b_rate) ) then
        Reaction.Break (BSet.pick_reaction randstate reac_mgr.b_set)
      else Reaction.Collision (CSet.pick_reaction randstate reac_mgr.c_set)
    in
    logger.info ~ltags:(lazy ["reaction", Reaction.to_yojson res; "reacs", to_yojson reac_mgr])"picked reaction";
    Some res)

(** update one reaction rate *)
let rec update_reaction_rate (reac : Reaction.t) reac_mgr =
  match reac with
  | Grab g -> GSet.update_rate g reac_mgr.g_set
  | Transition t -> TSet.update_rate t reac_mgr.t_set
  | Break b -> BSet.update_rate b reac_mgr.b_set
  | Collision c -> CSet.update_rate c reac_mgr.c_set

(** update all reactions rates *)
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
