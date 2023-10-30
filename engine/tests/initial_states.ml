(** Loads initial bactery states to use in other tests *)

open Bacterie_libs


let load name =
  let bact_sig = Bacterie.BactSig.of_yojson
      ( Yojson.Safe.from_file ("./bact_states/" ^ name ^ ".json" ))
                   |> Base.Result.ok_or_failwith
  in Bacterie.BactSig.to_bact bact_sig

let simple_bind = load "simple_bind"
let grab_amol = load "grab_amol"
let simple_break  = load "simple_break"
let simple_collision = load "simple_collision"
let simple_cycle = load "simple_cycle"
let simple_grab_release = load "simple_grab_release"
let simple_split = load "simple_split"
