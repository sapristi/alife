open Local_libs
open Bacterie_libs

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
  
let init (c : config) (sim : t) =
  let make_bact i =
    let reporter : Reporter.t = 
      {
        loggers = [Reporter.cli_logger; Reporter.make_file_logger "reactions"];
        prefix = (fun () -> ("[Reac_mgr]"));
        suffix = (fun () -> "");
      } in
    
    Bacterie.make ~env:c.environment ~bact_sig:c.bact_initial_state ~reporter:reporter () in
  
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
