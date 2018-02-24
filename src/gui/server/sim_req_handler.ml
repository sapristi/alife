type req_return_type =
  | Message of string
  | Error of string
  | Bact of Bacterie.t

let handle_sim_req (sim : Simulator.t) (cgi:Netcgi.cgi) : req_return_type  =

  
  let init (sim : Simulator.t) (cgi:Netcgi.cgi) =
    let config_str = (cgi#argument_value "config") in
    let config_json = Yojson.Safe.from_string config_str in
    match Simulator.config_of_yojson config_json with
    | Ok config ->
       Simulator.init config sim;
       Message (Yojson.Safe.to_string (Simulator.basic_info sim))
    | Error s -> failwith s


  and simulate (sim : Simulator.t) (cgi:Netcgi.cgi) =
    let reac_nb = int_of_string (cgi#argument_value "reac_nb") in
    Simulator.simulate reac_nb sim;
    Message "done."


  and send_bact_to_sandbox (sim : Simulator.t) (cgi : Netcgi.cgi) =
    let bact_index = int_of_string (cgi#argument_value "bact_index") in
    Bact (Simulator.get_bact bact_index sim)
    
    
  in let command = cgi # argument_value "command" in
     
     if command = "init"
     then init sim cgi
     else if command = "simulate"
     then simulate sim cgi
     else if command = "send_bact_to_sandbox"
     then send_bact_to_sandbox sim cgi
     else Error ("did not recognize command : "^command)
