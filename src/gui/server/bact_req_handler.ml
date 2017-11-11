open Bacterie
open Molecule
open Proteine
open Petri_net


(* *** pnet_from_mol *) 

let handle_bact_req bact (cgi:Netcgi.cgi) :string  = 
  let pnet_from_mol bact (cgi:Netcgi.cgi) =
    let mol_desc = cgi # argument_value "mol_desc" in
    let mol = Molecule.string_to_acid_list mol_desc in
    let pnet = Bacterie.get_pnet_from_mol mol bact
             
    in 
    
    let pnet_json = PetriNet.to_json pnet
    in
    let to_send_json =
      `Assoc
       ["purpose", `String "pnet_from_mol";
        "data",  `Assoc ["pnet", pnet_json]] 
    in
    Yojson.Safe.to_string to_send_json
    
(* *** get_bact_elements *)
    
  and get_bact_elements bact =
    let json_data = `Assoc
                     ["purpose", `String "bact_elements";
                      "data", (Bacterie.to_json bact)] in
    
    Yojson.Safe.to_string json_data
    
    
  and make_reactions bact =
    Bacterie.make_reactions bact;
    let json_data = `Assoc
                     ["purpose", `String "bactery_update_desc";
                      "data", (Bacterie.to_json bact)] in  
    Yojson.Safe.to_string json_data
    
  and commit_token_edit bact (cgi : Netcgi.cgi) =
    let token_str = cgi # argument_value "token" in
    let token_json = Yojson.Safe.from_string token_str in
    match (Token.Token.of_yojson token_json) with
    | Ok token -> print_endline (Token.Token.show token);
                  ""
    | Error s -> print_endline "error decoding token";
                 s

  and add_mol bact (cgi : Netcgi.cgi) = 
    let mol_desc = cgi # argument_value "mol_desc" in
    let mol = Molecule.string_to_acid_list mol_desc in
    Bacterie.add_molecule mol bact;
    "mol added"

  and save_state bact =
    "state saved"

  and load_state bact =
    "state loaded"
  in
  
  
  let command = cgi # argument_value "command" in
  
  if command = "pnet_from_mol"
  then pnet_from_mol bact cgi
  
  else if command = "get_elements"
  then get_bact_elements bact
  
  else if command = "make_reactions"
  then make_reactions bact
  
  else if command = "commit token edit"
  then commit_token_edit bact cgi

  else if command = "add_mol"
  then add_mol bact cgi

  else if command = "save_state"
  then  save_state bact

  else if command = "load_state"
  then load_state bact
  
  else ("did not recognize command : "^command)
;;
  
