open Server
open Reactors
open Local_libs
open Cmdliner
open Yaac_config
let () = Printexc.record_backtrace true;;



type params = {
    port: int;              [@default 1512] [@aka ["p"]] [@docv "PORT"]
    host: string;           [@default "0.0.0.0"] [@aka ["h"]] [@docv "HOST"]
    static_path : string;   [@default "_build/default/src/gui/js_client"] [@docv "PATH"]
    debug: bool;            [@default false] [@aka ["d"]]
                              (** Set most log level to debug *)
    stats: bool;            [@default false]
                              (** Generates running stats *)
  } [@@deriving cmdliner,show]
;;



let run_yaacs p = 

  if p.stats
  then
    begin
      let format_dummy : Logger.Formatter.t = fun item -> item.msg in
      let handler = Logger.Handler.make_file_handler Logger.Debug "stats" in
      let stats_reporter = Logger.get_logger "reacs_stats" in
      stats_reporter#add_handler handler;
      stats_reporter#set_level (Some Debug);
      Logger.Handler.set_formatter handler format_dummy;
      stats_reporter#info "ireactants areactants transitions grabs breaks  picked_dur treated_dur actions_dur";
    end
  else
    ();

  if p.debug
  then
    begin
      Config.config.bact_log_level <- Some Debug;
      Config.config.reacs_log_level <- Some Debug;
      Config.config.internal_log_level <- Some Debug;
    end
  else
    ();
      
  Web_server.start_srv
    p.static_path
    (Bact_server.make_req_handler
       (Simulator.make ())
       (Sandbox.of_yojson (Yojson.Safe.from_file "bact.json")))
    (p.host, p.port)
  

let _ = 

  let term = Term.(const run_yaacs $ params_cmdliner_term ()) in
  let info = Term.info Sys.argv.(0) in
  Term.eval (term, info);;

