
open Local_libs
open Cmdliner
open Yaac_config
open Server
open Reactors
open Easy_logging_yojson

let () = Printexc.record_backtrace true;;



type params = {
    port: int;              [@default 1512] [@aka ["p"]] [@docv "PORT"]
    host: string;           [@default "0.0.0.0"] [@aka ["h"]] [@docv "HOST"]
    static_path : string;   [@default "_build/default/src/gui/js_client"] [@docv "PATH"]
    debug: bool;            [@default false] [@aka ["d"]]
                              (** Set most log level to debug *)
    stats: bool;            [@default false]
                              (** Generates running stats *)
    log_level : Logging.level option; [@enum [("debug", Easy_logging__.Easy_logging_types.Debug); ("info", Info); ("warning", Warning); ("none", NoLevel)]]
    data_path : string;     [@default "./"] [@docv "PATH"]
    log_config : string     [@default ""]
  } [@@deriving cmdliner,show]
;;



let logger = Logging.get_logger  "Yaac.Main"
               


let run_yaacs p : unit= 
  logger#info "Starting Yaac with options :\n%s" @@ show_params p;
  
  if p.log_config = ""
  then Logging.load_config_str Config.default_log_config_str
  else Logging.load_config_file p.log_config;
  
  if p.stats
  then
    begin
      let format_dummy : Handlers.log_formatter = fun item  -> item.msg in
      let handler = Handlers.make (File ("stats", Debug)) in
      let stats_reporter = Logging.get_logger "Yaac.stats" in
      stats_reporter#add_handler handler;
      Handlers.set_formatter handler format_dummy;
      stats_reporter#info "ireactants areactants transitions grabs breaks  picked_dur treated_dur actions_dur";
    end
  else
    ();
  begin 
    match p.log_level with
    | None -> ()
    | Some lvl ->   let root_logger = Logging.get_logger "Yaac" in  
                    root_logger#set_level lvl;
  end;
                  
                  
    Web_server.start_srv
    (p.data_path ^ p.static_path)
    (Bact_server.make_req_handler
       (Simulator.make ())
       (Sandbox.of_yojson (Yojson.Safe.from_file  @@ p.data_path^"bact.json")))
    (p.host, p.port)
  

let _ = 
  
  let term = Term.(const run_yaacs $ params_cmdliner_term ()) in
  let doc = "Runs the Yaac server" in
  let info = Term.info Sys.argv.(0) ~doc in
  Term.eval (term, info)

