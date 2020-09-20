
open Bacterie_libs
open Local_libs
open Yaac_config
open Easy_logging_yojson
open Numeric

let logger = Logging.get_logger "Yaac.Reactor.Sandbox"


type signature = {
  bact: Bacterie.bact_sig;
  env: Environment.t;
  seed: int;
}
[@@deriving yojson]

let empty_sig = {
  bact = Bacterie.null_sig;
  env = Environment.null_env;
  seed = 0;
}


type t =
  {
    bact : Bacterie.t ref;
    env : Environment.t ref;
    seed: int ref
  }

let to_signature (sandbox: t) : signature =
  {
    bact = Bacterie.to_sig !(sandbox.bact);
    env = !(sandbox.env);
    seed = !(sandbox.seed);
  }

let of_signature (s: signature): t =
  let renv = ref s.env in
  let bact = ref (Bacterie.make ~bact_sig:s.bact renv) in
  {bact = bact; env = renv; seed=ref s.seed}


let make_empty () = of_signature empty_sig

let to_yojson = fun s -> s |> to_signature |> signature_to_yojson
let of_yojson = fun json -> json |> signature_of_yojson |> Result.map of_signature

let set_from_signature (sandbox:t) (signature:signature) =
  sandbox.bact :=  Bacterie.make ~bact_sig:(signature.bact) (ref signature.env);
  sandbox.env := signature.env;
  sandbox.seed := signature.seed
(* let of_state state_name =
 *   List.find (fun (n,_) -> n = state_name) !bact_states
 *   |> fun (_, state) -> of_yojson state
 *
 * let update_from_state sandbox state_name =
 *   List.find (fun (n,_) -> n = state_name) !bact_states
 *   |> fun (_, state) -> update_from_yojson sandbox state *)

let load_sigs_from_dir bact_states_path =
  Misc_library.list_files ~file_type:"json" bact_states_path
  |> List.map (fun x ->
      Filename.remove_extension (Filename.basename x),
      x |> Yojson.Safe.from_file |> signature_of_yojson |> Result.get_ok)
