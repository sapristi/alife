
open Bacterie_libs
open Local_libs
type t =
  {
    bact : Bacterie.t ref;
    env : Environment.t ref;
  }


  
let to_yojson (sandbox : t) =
  `Assoc ["bact", Bacterie.to_sig !(sandbox.bact)
                  |> Bacterie.bact_sig_to_yojson;
          "env", Environment.to_yojson !(sandbox.env)]

let of_yojson json : t =
  let reporter : Reporter.t = 
    {
      loggers = [Reporter.cli_logger; Reporter.make_file_logger "reactions"];
      prefix = (fun () -> ("[Reac_mgr]"));
      suffix = (fun () -> "");
    } in

  let json_safe = Yojson.Safe.from_file "bact.json" in
  let env_json = Yojson.Safe.Util.member "env" json_safe
  and bact_sig_json = Yojson.Safe.Util.member "bact" json_safe
  in
  match (Environment.of_yojson env_json, Bacterie.bact_sig_of_yojson bact_sig_json) with
  | (Ok env, Ok bact_sig) -> 
     let bact = ref (Bacterie.make ~env:env ~reporter:reporter ~initial_state:bact_sig ())
     and renv = ref env in
     {bact = bact; env = renv}
  | _ -> failwith "error loading sandbox json" 
  
  
