
open Bacterie_libs
open Local_libs
open Yaac_config
open Easy_logging


let logger = Logging.get_logger "Yaac.Reactor.Sandbox"
               


                  
type t =
  {
    bact : Bacterie.t ref;
    env : Environment.t ref;
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
     let bact = ref (Bacterie.make ~bact_sig renv)
     and renv = renv in
     {bact = bact; env = renv}
  | _  -> failwith  "error loading sandbox json" 
  
  
