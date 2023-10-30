open Easy_logging_yojson

let logger = Logging.get_logger "Yaac.Bact.Reactions"

include PRNG.Splitmix.State

type t = PRNG.Splitmix.State.t = { mutable seed : int64; gamma : int64 }
[@@deriving yojson]

let bernouil randstate q =
  let q' = Q.to_float q in
  float randstate 1. < q'

let bernouil_f randstate q = float randstate 1. < q

let pick_from_list randstate l =
  let n = int randstate (List.length l) in
  List.nth l n

let pick_from_array randstate a =
  let n = int randstate (Array.length a) in
  a.(n)

let q randstate bound = Q.(of_float (float randstate 1.) * bound)

(* TODO: better algo: use streams ? *)
let pick_from_weighted_list randstate total_weight l =
  let rec aux target_weight l =
    match l with
    | [] ->
        let msg = "Cannot pick from empty list" in
        logger#serror msg;
        failwith msg
    | (weight, elem) :: t ->
        logger#info "Aux: weight (%s), target (%s)"
          (Numeric.Q.to_string weight)
          (Numeric.Q.to_string target_weight);
        let open Numeric.Q in
        if weight >= target_weight then elem else aux (target_weight - weight) t
  in
  let target_weight = q randstate total_weight in
  logger#info "Random: total (%s), target (%s)"
    (Numeric.Q.to_string total_weight)
    (Numeric.Q.to_string target_weight);
  aux target_weight l
