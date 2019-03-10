open Local_libs
open Bacterie_libs
open Yaacs_config
type config = {
    environment : Environment.t;
    bact_nb : int;
    bact_initial_state : Bacterie.bact_sig;
  }
                [@@deriving make, yojson]

type simulator =
  | Uninitialised
  | Initialised of (Bacterie.t array)

type t =
  {mutable simulator : simulator;}
  
let make (): t =
  {simulator = Uninitialised;}


let sim_file_log_handler = Logger.Handler.make_file_handler Logger.Debug "sim";;
Logger.Handler.register_handler "sim" sim_file_log_handler
  
let reacs_reporter = new Logger.logger "Reac_mgr"
                       Config.simulator_config.reacs_log_level
                       [Logger.Handler.Cli Debug;
                        Logger.Handler.Reg "sim"] 
                   
let bact_reporter = new Logger.logger "Bactery"
                       Config.simulator_config.bact_log_level
                      [Logger.Handler.Cli Debug;
                      Logger.Handler.Reg "sim"] 
                   
  
let init (c : config) (sim : t) =
  let make_bact i =
    Bacterie.make ~env:c.environment
                  ~bact_sig:c.bact_initial_state
                  ~reacs_reporter:reacs_reporter
                  ~bact_reporter:bact_reporter () in
  
  let b_array = Array.init c.bact_nb make_bact
  in sim.simulator <- Initialised (b_array)

let get_bact n sim =
  match sim.simulator with
  | Uninitialised -> failwith "simulator uninitialised"
  | Initialised ba -> ba.(n)
                   
   
let simulate (n : int) (sim :t) =
  match sim.simulator with
  | Uninitialised -> failwith "simulator uninitialised"
  | Initialised ba ->
     Array.iter (fun b ->
         for i = 0 to n-1 do
           Bacterie.next_reaction b;
         done) ba

type sim_sig = {bact_nb : int;}
                 [@@ deriving yojson]
             
let basic_info (sim :t) =
  let sim_sig = 
    match sim.simulator with
    | Uninitialised -> {bact_nb = 0}
    | Initialised ba -> {bact_nb = Array.length ba;}
  in sim_sig_to_yojson sim_sig
