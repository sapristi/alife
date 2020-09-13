
open Local_libs
open Cmdliner
open Yaac_config
open Server
open Reactors
open Easy_logging_yojson
open Lwt.Infix

let () = Printexc.record_backtrace true;;


type params = {
  port: int;              [@default 1512] [@aka ["p"]] [@docv "PORT"]
  host: string;           [@default "0.0.0.0"] [@aka ["h"]] [@docv "HOST"]
  static_path : string;   [@default "client"] [@docv "PATH"]
  debug: bool;            [@default false] [@aka ["d"]]
  (** Set most log level to debug *)
  stats: bool;            [@default false]
  (** Generates running stats *)
  log_level : Logging.level option; [@enum [("debug", Logging.Debug); ("info", Info); ("warning", Warning); ("none", NoLevel)]]
  data_path : string;     [@default "./data/"] [@docv "PATH"]
  log_config : string;     [@default ""]
  random_seed: int option
} [@@deriving cmdliner,show]
;;

let logger = Logging.get_logger  "Yaac.Main"

let run_yaacs p : unit=
  logger#info "Starting Yaac with options :\n%s" @@ show_params p;

  let db_uri = Format.sprintf "sqlite3:%stest.sqlite3" p.data_path in
  begin
    match p.random_seed with
    | None -> Random.self_init ()
    | Some i -> Random.init i
  end;
  if p.log_config = ""
  then Logging.load_global_config_str Config.default_log_config_str
  else Logging.load_global_config_file p.log_config;

  if p.stats
  then
    begin
      let format_dummy : Handlers.log_formatter = fun item  -> item.msg in
      let handler = Handlers.make (File ("stats", Debug)) in
      let stats_reporter = Logging.get_logger "Yaac.stats" in
      stats_reporter#add_handler handler;
      Handlers.set_formatter handler format_dummy;
      stats_reporter#info "ireactants areactants transitions grabs breaks  picked_dur treated_dur actions_dur"
      |> ignore
    end
  else
    ();
  begin
    match p.log_level with
    | None -> ()
    | Some lvl ->   let root_logger = Logging.get_logger "Yaac" in
      root_logger#set_level lvl;
  end;
  Sandbox.init_states (p.data_path^"/bact_states");

  let pipe = Lwt_pipe.create ~max_size:10 () in


  let pipe_handler : Easy_logging_yojson.Handlers.t = {
    fmt = Easy_logging__.Formatters.format_json;
    level = Logging.Debug;
    filters = [];
    output = (fun s -> Lwt.async (fun () -> Lwt_pipe.write_exn pipe s))
  }
  in
  let root_logger = Logging.get_logger "Yaac" in
  root_logger#add_handler pipe_handler;


  let sandbox_init = List.map
      (fun (x,y) -> (x, "", y))
      (Sandbox.load_states (p.data_path^"/bact_states")) in
  Lwt.join [
    Yaac_db.init db_uri sandbox_init;
    Web_server.run
      p.port
      (p.static_path)
      (Bact_server.make_routes
         (Simulator.make ())
         (Sandbox.make_empty ())
      );
    Ws_server.run pipe ();
  ]

  |> Lwt_main.run

let _ =

  let term = Term.(const run_yaacs $ params_cmdliner_term ()) in
  let doc = "Runs the Yaac server" in
  let info = Term.info Sys.argv.(0) ~doc in
  Term.eval (term, info)
