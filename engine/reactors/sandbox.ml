
open Bacterie_libs
open Local_libs
(* open Yaac_config *)
open Easy_logging_yojson
open Numeric

let logger = Logging.get_logger "Yaac.Reactor.Sandbox"


type signature = {
  bact: Bacterie.bact_sig;
  env: Environment.t;
  randstate: Random_s.t
}
[@@deriving yojson]

let empty_sig = {
  bact = Bacterie.null_sig;
  env = Environment.null_env;
  randstate = {
    Random_s.seed = 8085733080487790103L;
    gamma = -7046029254386353131L
  }
}

type t = Bacterie.t ref

let to_signature (sandbox: t) : signature =
  {
    bact = Bacterie.to_sig !sandbox;
    env = !(!sandbox.env);
    randstate = !(!sandbox.randstate);
  }

let of_signature (s: signature): t =
  ref (Bacterie.from_sig s.bact ~env:s.env ~randstate:s.randstate)


let make_empty () = of_signature empty_sig

let to_yojson = fun s -> s |> to_signature |> signature_to_yojson
let of_yojson = fun json -> json |> signature_of_yojson |> Result.map of_signature

let set_from_signature (sandbox:t) (s:signature) =
  sandbox := (Bacterie.from_sig s.bact ~env:s.env ~randstate:s.randstate)

let load_sigs_from_dir bact_states_path =
  Misc_library.list_files ~file_type:"json" bact_states_path
  |> List.map (fun x ->
      Filename.remove_extension (Filename.basename x),
      x |> Yojson.Safe.from_file |> signature_of_yojson |> Result.get_ok)


(* let replace sandbox new_sandbox =
 *   sandbox.bact := !(new_sandbox.bact);
 *   sandbox.env := !(new_sandbox.env);
 *   sandbox.seed := !(new_sandbox.seed) *)
