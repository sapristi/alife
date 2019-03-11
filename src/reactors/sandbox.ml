
open Bacterie_libs
open Local_libs
open Yaac_config
   

let reacs_reporter = new Logger.logger "Reac_mgr"
                       Config.config.reacs_log_level
                       [Logger.Handler.Cli Debug;
                        Logger.Handler.File ("reactions", Debug)] 
                   
let bact_reporter = new Logger.logger "Bactery"
                      Config.config.bact_log_level
                      [Logger.Handler.Cli Debug;
                       Logger.Handler.File ("bactery", Debug)] 

type t =
  {
    bact : Bacterie.t ref;
    env : Environment.t ref;
  }

  
let to_yojson (sandbox : t) =
  `Assoc ["bact", Bacterie.to_sig !(sandbox.bact)
                  |> Bacterie.bact_sig_to_yojson;
          "env", Environment.to_yojson !(sandbox.env)]

let of_yojson  ?(bact_reporter=bact_reporter)
              ?(reacs_reporter=reacs_reporter) json : t=

  let env_json = Yojson.Safe.Util.member "env" json
  and bact_sig_json = Yojson.Safe.Util.member "bact" json
  in
  match (Environment.of_yojson env_json, Bacterie.bact_sig_of_yojson bact_sig_json) with
  | (Ok env, Ok bact_sig) -> 
     let bact = ref (Bacterie.make ~env:env
                                   ~reacs_reporter:reacs_reporter
                                   ~bact_reporter:bact_reporter
                                   ~bact_sig:bact_sig ())
     and renv = ref env in
     {bact = bact; env = renv}
  | _ -> failwith "error loading sandbox json" 
  
  
