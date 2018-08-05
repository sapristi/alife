open Bacterie_libs
open Reactors

          
let init (sim : Simulator.t) (cgi:Netcgi.cgi) =
  let config_str = (cgi#argument_value "config") in
  let config_json = Yojson.Safe.from_string config_str in
  match Simulator.config_of_yojson config_json with
  | Ok config ->
     Simulator.init config sim;
     Yojson.Safe.to_string (Simulator.basic_info sim)
  | Error s -> failwith s
             

let simulate (sim : Simulator.t) (cgi:Netcgi.cgi) =
  let reac_nb = int_of_string (cgi#argument_value "reac_nb") in
  Simulator.simulate reac_nb sim;
  "done."
  

let send_bact_to_sandbox (sim : Simulator.t) (cgi : Netcgi.cgi) =
  let bact_index = int_of_string (cgi#argument_value "bact_index") in
 Simulator.get_bact bact_index sim
  

let server_functions =
  ["init", init;
   "simulate",simulate;
   (*   "send_bact_to_sandbox",send_bact_to_sandbox; *)
  ]
