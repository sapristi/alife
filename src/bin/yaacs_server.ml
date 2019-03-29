
open Local_libs
open Cmdliner
open Yaac_config
open Server
open Reactors
open Easy_logging

let () = Printexc.record_backtrace true;;



type params = {
    port: int;              [@default 1512] [@aka ["p"]] [@docv "PORT"]
    host: string;           [@default "0.0.0.0"] [@aka ["h"]] [@docv "HOST"]
    static_path : string;   [@default "_build/default/src/gui/js_client"] [@docv "PATH"]
    debug: bool;            [@default false] [@aka ["d"]]
                              (** Set most log level to debug *)
    stats: bool;            [@default false]
                              (** Generates running stats *)
    log_level : log_level;  [@default Info] [@enum [("debug", Easy_logging__Easy_logging_types.Debug); ("info", Info); ("warning", Warning); ("none", NoLevel)]]
    data_path : string [@default "./"] [@docv "PATH"]
  } [@@deriving cmdliner,show]
;;



let logger = Logging.make_logger  "Yaac.Main"
               Warning [Cli Debug];;


let run_yaacs p : unit= 
  
  let file_handler_defaults : Default_handlers.file_handler_defaults_t =  {
      logs_folder = p.data_path^"logs/";
      truncate = true;
      file_perms = 0o660;
    } in Default_handlers.set_file_handler_defaults file_handler_defaults;
    
  if p.stats
  then
    begin
      let format_dummy : Default_handlers.log_formatter = fun item  -> item.msg in
      let handler = Default_handlers.make (File ("stats", Debug)) in
      let stats_reporter = Logging.get_logger "reacs_stats" in
      stats_reporter#add_handler handler;
      stats_reporter#set_level Debug;
      Default_handlers.set_formatter handler format_dummy;
      stats_reporter#info "ireactants areactants transitions grabs breaks  picked_dur treated_dur actions_dur";
    end
  else
    ();

  Logging.set_level "Yaac" p.log_level;
    
  logger#info "Starting Yaac with options :\n%s" @@ show_params p;

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

