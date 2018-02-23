
type config = {
    reacs_config : Reac_mgr.config;
    bact_nb : int;
    bact_initial_state : Bacterie.bact_sig;
  }
                [@@deriving make, yojson]

type simulator =
  | Uninitialised
  | Initialised of (Bacterie.t array)
                     [@@deriving yojson]
type t =
  {mutable simulator : simulator;}
    [@@ deriving yojson]
  
let make (): t =
  {simulator = Uninitialised;}
  
let init (c : config) (sim : t) =
  let make_bact i =
    Bacterie.make c.bact_initial_state  in
  
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
