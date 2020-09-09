
open Bacterie_libs
open Local_libs
open Yaac_config
open Easy_logging_yojson
open Numeric

let logger = Logging.get_logger "Yaac.Reactor.Sandbox"


let bact_states = ref []

let init_states bact_states_path =
  bact_states :=
    Misc_library.list_files ~file_type:"json" bact_states_path
    |> List.map (fun x ->
        logger#sdebug x;
          Filename.remove_extension (Filename.basename x),
          Yojson.Safe.from_file x)

type t =
  {
    bact : Bacterie.t ref;
    env : Environment.t ref;
  }


let make_empty () =
  let (env: Environment.t) = {transition_rate = Q.of_int 10;
                              grab_rate = Q.of_int 1;
                              break_rate = Q.of_int 0;
                              collision_rate = Q.of_int 0}
  in let renv = ref env in
  {
    bact= ref (Bacterie.make renv);
    env= renv;
  }


let to_yojson (sandbox : t) =
  `Assoc ["bact", Bacterie.to_sig !(sandbox.bact)
                  |> Bacterie.bact_sig_to_yojson;
          "env", Environment.to_yojson !(sandbox.env)]

let of_yojson   json : t=

  let env_json = Yojson.Safe.Util.member "env" json
  and bact_sig_json = Yojson.Safe.Util.member "bact" json
  in
  match (Environment.of_yojson env_json, Bacterie.bact_sig_of_yojson bact_sig_json) with
  | (Ok env, Ok bact_sig) ->
     let renv = ref env in
     let bact = ref (Bacterie.make ~bact_sig renv) in
     {bact = bact; env = renv}
  | _  -> failwith  "error loading sandbox json"


let update_from_yojson sandbox json =
  let env_json = Yojson.Safe.Util.member "env" json
  and bact_sig_json = Yojson.Safe.Util.member "bact" json
  in
  match (Environment.of_yojson env_json, Bacterie.bact_sig_of_yojson bact_sig_json) with
  | (Ok env, Ok bact_sig) ->
    sandbox.env := env;
    sandbox.bact := Bacterie.make ~bact_sig sandbox.env
  | _  -> failwith  "error loading sandbox json"


let of_state state_name =
  List.find (fun (n,_) -> n = state_name) !bact_states
  |> fun (_, state) -> of_yojson state

let update_from_state sandbox state_name =
  List.find (fun (n,_) -> n = state_name) !bact_states
  |> fun (_, state) -> update_from_yojson sandbox state
