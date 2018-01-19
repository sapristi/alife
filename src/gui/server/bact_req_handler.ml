
(* *** pnet_from_mol *) 

let handle_bact_req bact (cgi:Netcgi.cgi) :string  = 
  let pnet_from_mol (bact : Bacterie.t) (cgi:Netcgi.cgi) =
    let mol = cgi # argument_value "mol_desc" in
    match Bacterie.MolMap.find mol bact.molecules with
    | _,Some pnet,_ ->
       let pnet_json = Petri_net.to_json pnet
       in
       let to_send_json =
         `Assoc
          ["purpose", `String "pnet_from_mol";
           "data",  `Assoc ["pnet", pnet_json]] 
       in
       Yojson.Safe.to_string to_send_json
    | _,None,_ -> "no pnet for this mol"
(* *** get_bact_elements *)
    
  and get_bact_elements bact =
    let json_data = `Assoc
                     ["purpose", `String "bact_elements";
                      "data", (Bacterie.to_json bact)] in
    Yojson.Safe.to_string json_data
    
    
  in

  let next_reactions bact =
    let n_str = cgi # argument_value "n" in
    let n = int_of_string n_str in 
    for i = 0 to n do
      Bacterie.next_reaction bact;
    done;
    let json_data = `Assoc
                     ["purpose", `String "bactery_update_desc";
                      "data", (Bacterie.to_json bact)] in  
    Yojson.Safe.to_string json_data
    
  and commit_token_edit (bact : Bacterie.t) (cgi : Netcgi.cgi)
      : string =
    let token_str = cgi # argument_value "token" in
    let token_json = Yojson.Safe.from_string token_str in

    match (Token.option_t_of_yojson token_json) with
    | Ok token_o ->
       (
         let mol = cgi # argument_value "molecule" in
         let place_index_str = cgi # argument_value "place_index" in
         let place_index = int_of_string place_index_str in
         
         match Bacterie.MolMap.find mol bact.molecules with
         | _, Some pnet,_ ->
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
         | _, None,_ -> "no pnet for this mol"
       )
    | Error s -> print_endline "error decoding token";
                 s
   
    
  and launch_transition (bact : Bacterie.t) (cgi : Netcgi.cgi) =
    let mol = cgi # argument_value "molecule" in
    let trans_index_str = cgi # argument_value "transition_index" in
    let trans_index = int_of_string trans_index_str in
    
    match Bacterie.MolMap.find mol bact.molecules with
    | _, Some pnet,_ -> 
    
       Petri_net.launch_transition_by_id trans_index pnet;
       Petri_net.update_launchables pnet;
       
       let pnet_json = Petri_net.to_json pnet
       in
       let to_send_json =
      `Assoc
       ["purpose", `String "pnet_update";
        "data",  `Assoc ["pnet", pnet_json]] in  
       Yojson.Safe.to_string to_send_json
    | _, None,_ ->  "no pnet for this mol"

  and add_mol bact (cgi : Netcgi.cgi) = 
    let mol = cgi # argument_value "mol_desc" in
    Bacterie.add_molecule mol bact;
    get_bact_elements bact;

  and remove_mol bact (cgi : Netcgi.cgi) = 
    let mol = cgi # argument_value "mol_desc" in
    Bacterie.remove_molecule mol bact;
    get_bact_elements bact;

  and set_mol_quantity bact (cgi : Netcgi.cgi) = 
    let mol = cgi # argument_value "mol_desc"
    and n = cgi # argument_value "mol_quantity" in
    Bacterie.set_mol_quantity mol (int_of_string n) bact;
    get_bact_elements bact;

    (*
  and save_state bact =
    let data_json = Bacterie.to_json bact in
    Yojson.Safe.to_file "bact.save" data_json;
    "state saved"
     *)
  and reset_state bact =
    let data_json =  Yojson.Safe.from_file "bact.save" in
    Bacterie.json_reset data_json bact;
    get_bact_elements bact;

  and set_state bact (cgi : Netcgi.cgi) =
    let bact_desc = cgi # argument_value "bact_desc" in
    let bact_desc_json = Yojson.Safe.from_string bact_desc in
    Bacterie.json_reset bact_desc_json bact;
    get_bact_elements bact;
    
  in
  
  
  let command = cgi # argument_value "command" in
  
  if command = "pnet_from_mol"
  then pnet_from_mol bact cgi
  
  else if command = "get_elements"
  then get_bact_elements bact
  
  else if command = "next_reactions"
  then next_reactions bact
  
  else if command = "commit token edit"
  then commit_token_edit bact cgi
  
  else if command = "launch_transition"
  then launch_transition bact cgi

  else if command = "add_mol"
  then add_mol bact cgi
  
  else  if command = "remove_mol"
  then remove_mol bact cgi

  else if command = "set_mol_quantity"
  then set_mol_quantity bact cgi

  else if command = "reset_bactery"
  then reset_state bact
  
  else if command = "set_bactery"
  then set_state bact cgi
  
  else ("did not recognize command : "^command)
;;
  
