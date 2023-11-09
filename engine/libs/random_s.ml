
let logger = Alog.make_logger "Yaac.Bact.Reactions"

include PRNG.Splitmix.State

type t = PRNG.Splitmix.State.t = { mutable seed : int64; gamma : int64 }
[@@deriving yojson, show, eq]

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
        logger.error msg;
        failwith msg
    | (weight, elem) :: t ->
      logger.info ~tags:["weight", Numeric.Q.to_yojson weight;
                         "target", Numeric.Q.to_yojson target_weight] "Aux";
        let open Numeric.Q in
        if weight >= target_weight then elem else aux (target_weight - weight) t
  in
  let target_weight = q randstate total_weight in
  logger.info ~tags:[ "total", Numeric.Q.to_yojson total_weight;
                      "target", Numeric.Q.to_yojson target_weight] "Pick from weighted list";
  aux target_weight l

let shuffle_array randstate a =
  for i = Array.length a - 1 downto 1 do
    let j = int randstate (i + 1) in
    let b = a.(i) in
    a.(i) <- a.(j);
    a.(j) <- b
  done

let shuffle_list randstate l =
  let a = Array.of_list l in
  shuffle_array randstate a;
  Array.to_list a
