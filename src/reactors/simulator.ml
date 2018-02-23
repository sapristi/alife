
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
  {mutable simulator : simulator;
   sandbox: Bacterie.t ref option}
    [@@ deriving yojson]
  
let make ?(sandbox=None) (): t =
  {simulator = Uninitialised;
   sandbox;}
  
let init (c : config) (sim : t) =
  let make_bact i =
    Bacterie.make_empty ~rcfg:c.reacs_config ()
  in
  
  let b_array = Array.init c.bact_nb make_bact
  in sim.simulator <- Initialised (b_array)
   
   
let simulate (n : int) (sim :t) =
  match sim.simulator with
  | Uninitialised -> failwith "simulator uninitialised"
  | Initialised ba ->
     Array.iter (fun b ->
         for i = 0 to n-1 do
           Bacterie.next_reaction b;
         done) ba

