
open Bacterie_libs
open Reactors

open Opium.Std

          
let init (sim : Simulator.t) (req) =
  let config_str = (param req "config") in
  let config_json = Yojson.Safe.from_string config_str in
  (
  match Simulator.config_of_yojson config_json with
  | Ok config ->
     Simulator.init config sim;
     `Json (Simulator.basic_info sim)
  | Error s ->
    `Error s
) |> Lwt.return          

let simulate (sim : Simulator.t) (req) =
  let reac_nb = int_of_string (param req "reac_nb") in
  Simulator.simulate reac_nb sim;
  `Empty |> Lwt.return

let send_bact_to_sandbox (sim : Simulator.t) (req) =
  let bact_index = int_of_string (param req "bact_index") in
  Simulator.get_bact bact_index sim;
  `Empty |> Lwt.return
  

let server_functions =
  [post, "/simulator", init;
   post, "/simlator/simulate",simulate;
   (*   "send_bact_to_sandbox",send_bact_to_sandbox; *)
  ]
