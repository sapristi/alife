open Local_libs
open Misc_library
open Numeric
open Local_libs
open Base_chemistry
open Reactions_implem

let logger = Jlog.make_logger "Yaac.Bact.Reactions"

(** Reactions

Defines a functor that takes a Reactant module and makes reactions out
of it. Possible reactions are :

+ Grab :
  grab between an active molecule and another reactant

+ Transition :
  launches a transition in an active molecule

+ Break :
  a molecules breaks in two pieces


Implem details
==============

A reaction is a record with :
+ for each reactant, a field with a reference to this reactant
+ a mutable rate field to store the rate


In a reaction module, the following functions are defined

+ calculate_rate (not public) :
  calculates the rate at which the reaction takes place

+ rate:
  returns the value in rate field

+ update_rate :
  modifies rate field with a newly calculated value
  and returns the difference between old and new rate
  (for easy update of global rate)

+ make : creates the reaction from references to the reactants

+ eval : performs the reaction on the reactants and returns a list
  of actions to be performed at higher level

* TODO tasks
     + clearly define what is to be done in eval
       and what is to be returned higher, and why *)


module type REACTANT = sig
  type reac
  type reacSet
  [@@deriving to_yojson]

  module type REACTANT_DEFAULT = sig
    type t
    type reac
    type reacSet
    [@@deriving to_yojson]

    val show : t -> string
    val to_yojson : t -> Yojson.Safe.t
    val show_reacSet : reacSet -> string
    val pp_reacSet : Format.formatter -> reacSet -> unit
    val pp : Format.formatter -> t -> unit
    val compare : t -> t -> int
    val equal : t -> t -> bool
    val mol : t -> Molecule.t
    val qtt : t -> int
    val reacs : t -> reacSet
    val remove_reac : reac -> t -> unit
    val add_reac : reac -> t -> unit
  end

  module ImolSet : sig
    type t = private {
      mol : Molecule.t;
      mutable qtt : int;
      reacs : reacSet ref;
      mutable ambient : bool;
    }

    val make_new : ?qtt:int -> ?ambient:bool -> Molecule.t -> t
    val add_to_qtt : int -> t -> unit
    val set_qtt : int -> t -> unit
    val set_ambient : bool -> t -> unit
    val copy : t -> t

    include
      REACTANT_DEFAULT
        with type t := t
         and type reac := reac
         and type reacSet := reacSet
  end

  module Amol : sig
    type t = private {
      mol : Molecule.t;
      pnet : Petri_net.t;
      reacs : reacSet ref;
    }

    val make_new : Petri_net.t -> t

    include
      REACTANT_DEFAULT
        with type t := t
         and type reac := reac
         and type reacSet := reacSet
  end

  type t = Amol of Amol.t | ImolSet of ImolSet.t | Dummy

  include
    REACTANT_DEFAULT
      with type t := t
       and type reac := reac
       and type reacSet := reacSet
end


(** Partial Module type for a reactant
    Constains definitions that can be shared - used in reaction.ml
*)
module type REAC_PARTIAL = sig
  type t
  type build_t

  val name : string
  val show : t -> string
  val to_yojson : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal: t -> t -> bool
  val compare : t -> t -> int
  val rate : t -> Q.t
  val update_rate : t -> Q.t
  val make : build_t -> t
  val get_reactants : t -> build_t

end

module ReactionsM (R : REACTANT) = struct
  type effect =
    | T_effects of Place.transition_effect list
    | Update_launchables of R.Amol.t
    | Remove_one of R.t
    | Update_reacs of R.reacSet
    | Remove_reacs of R.reacSet
    | Release_mol of Molecule.t
    | Release_tokens of Token.t list
  [@@deriving show, to_yojson]

  (** Module type for a reactant *)
  module type REAC = sig
    include REAC_PARTIAL
    val eval : Random_s.t -> t -> effect list
    val remove_reac_from_reactants : R.reac -> t -> unit
  end

  module Grab : REAC with type build_t = R.Amol.t * R.t = struct
    let name = "Grab"
    type t = {
      mutable rate : Q.t; [@compare fun a b -> 0] (* TODO: why this ? *)
      graber_data : R.Amol.t;
      grabed_data : R.t;
    }
    [@@deriving show, ord, to_yojson, eq]

    type build_t = R.Amol.t * R.t

    let calculate_rate ({ graber_data; grabed_data; _ } : t) =
      let mol = R.mol grabed_data and qtt = R.qtt grabed_data in
      Q.(Petri_net.grab_factor mol graber_data.pnet * of_int qtt)

    (* let rate ({ rate; _ } : t) : Q.t = rate *)
    let rate (g : t) : Q.t =
      let res = g.rate and calc = calculate_rate g in
      if Q.equal res calc
      then
        res
      else (
        logger.warning ~tags:["stored", to_yojson g; "computed", Q.to_yojson calc] "Rate error";
        failwith "problem"
      )

    let update_rate ({ rate; _ } as g : t) =
      let old_rate = rate in
      g.rate <- calculate_rate g;
      Q.(g.rate - old_rate)

    let make ((graber_data, grabed_data) : build_t) : t =
      {
        graber_data;
        grabed_data;
        rate = calculate_rate { graber_data; grabed_data; rate = Q.zero };
      }

    let eval randstate (g : t) : effect list =
      ignore (asymetric_grab randstate (R.mol g.grabed_data) g.graber_data.pnet);
      [
        Remove_one g.grabed_data;
        Update_launchables g.graber_data;
        Update_reacs (R.Amol.reacs g.graber_data);
      ]

    let remove_reac_from_reactants reac g =
      R.Amol.remove_reac reac g.graber_data;
      R.remove_reac reac g.grabed_data

    let get_reactants g = (g.graber_data, g.grabed_data)
  end


  module Transition : REAC with type build_t = R.Amol.t = struct
    let name = "Transition"
    type t = { mutable rate : Q.t; [@compare fun a b -> 0] amd : R.Amol.t }
    [@@deriving ord, show, to_yojson, eq]

    type build_t = R.Amol.t

    let calculate_rate (t : t) = Q.of_int t.amd.pnet.launchables_nb

    (* let rate (t : t) = t.rate *)
    let rate (g : t) : Q.t =
      let res = g.rate and calc = calculate_rate g in
      if Q.equal res calc
      then
        res
      else (
        logger.warning ~tags:["stored", to_yojson g; "computed", Q.to_yojson calc] "Rate error";
        failwith "problem"
      )

    let update_rate ({ rate; _ } as t : t) =
      let old_rate = rate in
      t.rate <- calculate_rate t;
      Q.(t.rate - old_rate)

    let make (amd : build_t) =
      { rate = calculate_rate { amd; rate = Q.zero }; amd }

    let eval randstate (trans : t) : effect list =
      let t_effects =
        Petri_net.launch_random_transition randstate trans.amd.pnet
      in
      (*          Petri_net.update_launchables (!(trans.amd).pnet);*)
      [
        T_effects t_effects;
        Update_launchables trans.amd;
        Update_reacs (R.Amol.reacs trans.amd);
      ]

    let remove_reac_from_reactants reac g = ()
    let get_reactants t = t.amd
  end

  module Break : REAC with type build_t = R.t = struct
    let name = "Break"
    type t = { mutable rate : Q.t; [@compare fun a b -> 0] reactant : R.t }
    [@@deriving show, ord, to_yojson, eq]

    type build_t = R.t

    let calculate_rate ba =
      let mol = R.mol ba.reactant in
      Q.(sqrt (of_int (String.length mol) - one) * of_int (R.qtt ba.reactant))

    (* let rate ba = ba.rate *)
    let rate (g : t) : Q.t =
      let res = g.rate and calc = calculate_rate g in
      if Q.equal res calc
      then
        res
      else (
        logger.warning ~tags:["stored", to_yojson g; "computed", Q.to_yojson calc] "Rate error";
        failwith "problem"
      )

    let update_rate ba =
      let old_rate = ba.rate in
      ba.rate <- calculate_rate ba;
      Q.(ba.rate - old_rate)

    let make reactant =
      { reactant; rate = calculate_rate { reactant; rate = Q.zero } }

    let eval randstate ba =
      let mol = R.mol ba.reactant in
      let m1, m2 = break randstate mol in
      [ Remove_one ba.reactant; Release_mol m1; Release_mol m2 ]

    let remove_reac_from_reactants reac g = ()
    let get_reactants b = b.reactant
  end


  module Collision : REAC with type build_t = R.t * R.t = struct
    let name = "Collision"

    type t = { r1 : R.t; r2 : R.t }
    [@@deriving show, ord, to_yojson, eq]

    type build_t = R.t * R.t

    let calculate_rate c = failwith "This should not be used"
        (** Return length of mol instead or somehting like that ? *)

    let rate c = failwith "This should not be used"

    let update_rate c = failwith "This should not be used"

    let make (r1, r2) =
      { r1; r2; }

    let eval randstate { r1; r2 } =
      let m1 = R.mol r1 and m2 = R.mol r2 in
      let new_mols = collide randstate m1 m2 in

      logger.debug ~tags:["reactants", [%to_yojson:R.t list] [r1; r2 ]] "Random collision";
      let res = ref [] and new_mols_r = ref new_mols in
      (match extract_from_list !new_mols_r m1 with
      | Ok new_mols' -> new_mols_r := new_mols'
      | Error _ -> res := Remove_one r1 :: !res);
      (match extract_from_list !new_mols_r m2 with
      | Ok new_mols' -> new_mols_r := new_mols'
      | Error _ -> res := Remove_one r2 :: !res);
      !res @ List.map (fun m -> Release_mol m) !new_mols_r

    let remove_reac_from_reactants reac g = ()
    let get_reactants c = (c.r1, c.r2)
  end
end
