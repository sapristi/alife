

open Reactors
open Bacterie_libs

   

let handle_sandbox_req (sandbox : Sandbox.t) (cgi:Netcgi.cgi) :string  =

  let pnet_ids_from_mol  (sandbox : Sandbox.t) (cgi:Netcgi.cgi) =
    let mol = cgi # argument_value "mol_desc" in
    let pnet_ids = Bacterie.ARMap.get_pnet_ids mol !sandbox.areactants in
    let pnet_ids_json =
      `List (List.map (fun i -> `Int i) pnet_ids)
    in
    `Assoc
       ["purpose", `String "pnet_ids";
        "data", pnet_ids_json]
    |> Yojson.Safe.to_string
    
  
  and pnet_from_mol (sandbox : Sandbox.t) (cgi:Netcgi.cgi) =
    let mol = cgi # argument_value "mol_desc"
    and pnet_id = int_of_string (cgi# argument_value "pnet_id") in
    let pnet =  Bacterie.ARMap.find_pnet mol pnet_id !sandbox.areactants
    in
    let pnet_json = Petri_net.to_json pnet
    in
    `Assoc
     ["purpose", `String "pnet_from_mol";
      "data",  `Assoc ["pnet", pnet_json]] 
    |>  Yojson.Safe.to_string
(* *** get_bact_elements *)
    
  and get_bact_elements sandbox =
    let json_data = `Assoc
                     ["purpose", `String "bact_elements";
                      "data", (Bacterie.to_yojson !sandbox)] in
    Yojson.Safe.to_string json_data
    
    
  in

  let next_reactions sandbox =
    let n_str = cgi # argument_value "n" in
    let n = int_of_string n_str in 
    for i = 0 to n-1 do
      Bacterie.next_reaction !sandbox;
    done;
    let json_data = `Assoc
                     ["purpose", `String "bactery_update_desc";
                      "data", (Bacterie.to_yojson !sandbox)] in  
    Yojson.Safe.to_string json_data
    
  and commit_token_edit (sandbox : Sandbox.t) (cgi : Netcgi.cgi)
      : string =
    let token_str = cgi # argument_value "token" in
    let token_json = Yojson.Safe.from_string token_str in

    match (Token.option_t_of_yojson token_json) with
    | Ok token_o ->
       (
         let mol = cgi # argument_value "molecule" in
         let pnet_id = int_of_string (cgi # argument_value "pnet_id") in
         let place_index_str = cgi # argument_value "place_index" in
         let place_index = int_of_string place_index_str in
         
         let pnet = Bacterie.ARMap.find_pnet mol pnet_id !sandbox.areactants in
         (
           match token_o with
           | Some token -> 
              Place.set_token token pnet.places.(place_index);
           | None -> Place.remove_token pnet.places.(place_index);
         );
         Petri_net.update_launchables pnet;
         
         let pnet_json = Petri_net.to_json pnet
         in
         let to_send_json =
           `Assoc
            ["purpose", `String "pnet_update";
             "data",  `Assoc ["pnet", pnet_json]] in  
         Yojson.Safe.to_string to_send_json
         
       );
    | Error s -> print_endline "error decoding token";
                 s
   
    
  and launch_transition (sandbox : Sandbox.t) (cgi : Netcgi.cgi) =
    let mol = cgi # argument_value "molecule" 
    and pnet_id = int_of_string (cgi # argument_value "pnet_id") 
    and trans_index = cgi # argument_value "transition_index"
                      |> int_of_string in

    let pnet = Bacterie.ARMap.find_pnet mol pnet_id !sandbox.areactants in
    
    Petri_net.launch_transition_by_id trans_index pnet;
    Petri_net.update_launchables pnet;
    
    let pnet_json = Petri_net.to_json pnet
    in
      `Assoc
       ["purpose", `String "pnet_update";
        "data",  `Assoc ["pnet", pnet_json]]  
      |> Yojson.Safe.to_string 
    
  and add_mol sandbox (cgi : Netcgi.cgi) = 
    let mol = cgi # argument_value "mol_desc" in
    Bacterie.add_molecule mol !sandbox
    |> Bacterie.execute_actions !sandbox;
    get_bact_elements sandbox;

  and remove_mol (sandbox : Sandbox.t) (cgi : Netcgi.cgi) = 
    let mol = cgi # argument_value "mol_desc" in
    Bacterie.IRMap.remove_all mol !sandbox.ireactants
    |> Bacterie.execute_actions !sandbox;
    get_bact_elements sandbox;

  and set_mol_quantity (sandbox : Sandbox.t) (cgi : Netcgi.cgi) = 
    let mol = cgi # argument_value "mol_desc"
    and n = cgi # argument_value "mol_quantity" in
    Bacterie.IRMap.set_qtt  (int_of_string n) mol !sandbox.ireactants
    |> Bacterie.execute_actions !sandbox;
    get_bact_elements sandbox;

    (*
  and save_state bact =
    let data_json = Bacterie.to_json bact in
    Yojson.Safe.to_file "bact.save" data_json;
    "state saved"
     *)
  and reset_state sandbox =
    let data_json =  Yojson.Safe.from_file "bact.save" in
    Sandbox.json_reset data_json sandbox;
    get_bact_elements sandbox;

  and set_state sandbox (cgi : Netcgi.cgi) =
    let bact_desc = cgi # argument_value "bact_desc" in
    let bact_desc_json = Yojson.Safe.from_string bact_desc in
    Sandbox.json_reset bact_desc_json sandbox;
    get_bact_elements sandbox;
    
  in
  
  
  let command = cgi # argument_value "command" in

  
  if command = "pnet_ids_from_mol"
  then pnet_ids_from_mol sandbox cgi
  
  else if command = "pnet_from_mol"
  then pnet_from_mol sandbox cgi
  
  else if command = "get_elements"
  then get_bact_elements sandbox
  
  else if command = "next_reactions"
  then next_reactions sandbox
  
  else if command = "commit token edit"
  then commit_token_edit sandbox cgi
  
  else if command = "launch_transition"
  then launch_transition sandbox cgi

  else if command = "add_mol"
  then add_mol sandbox cgi
  
  else  if command = "remove_mol"
  then remove_mol sandbox cgi

  else if command = "set_mol_quantity"
  then set_mol_quantity sandbox cgi

  else if command = "reset_bactery"
  then reset_state sandbox
  
  else if command = "set_bactery"
  then set_state sandbox cgi
  
  else ("did not recognize command : "^command)

  
