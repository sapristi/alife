open Bacterie_libs
open Reactors

let init (sim : Simulator.t) req =
  let config_str = Opium.Request.query_exn "config" req in
  let config_json = Yojson.Safe.from_string config_str in
  (match Simulator.config_of_yojson config_json with
  | Ok config ->
      Simulator.init config sim;
      `Json (Simulator.basic_info sim)
  | Error s -> `Error s)
  |> Lwt.return

let simulate (sim : Simulator.t) req =
  let reac_nb = Opium.Request.query_exn "reac_nb" req |> int_of_string in
  Simulator.simulate reac_nb sim;
  `Empty |> Lwt.return

let send_bact_to_sandbox (sim : Simulator.t) req =
  let bact_index = Opium.Request.query_exn "bact_index" req |> int_of_string in
  Simulator.get_bact bact_index sim;
  `Empty |> Lwt.return

let server_functions =
  [
    (Opium.App.post, "/simulator", init);
    (Opium.App.post, "/simlator/simulate", simulate);
    (*   "send_bact_to_sandbox",send_bact_to_sandbox; *)
  ]
