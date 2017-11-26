(* * simulation server *)

(* ** preamble*)
open Bact_req_handler

let handle_general_req (cgi:Netcgi.cgi) : string =
(* *** prot_from_mol *)
  let prot_from_mol (cgi:Netcgi.cgi) : string =
    
    let mol = cgi # argument_value "mol_desc" in
    let prot = Molecule.to_proteine mol in
    let prot_json = Proteine.to_yojson prot
    in
    let to_send_json =
      `Assoc
       ["purpose", `String "prot_from_mol";
        "data", `Assoc ["prot", prot_json]] 
    in
    Yojson.Safe.to_string to_send_json
    
  and build_all_from_mol (cgi : Netcgi.cgi) : string =
    let mol = cgi # argument_value "mol_desc" in
    let prot = Molecule.to_proteine mol in
    let pnet = Petri_net.make_from_mol mol
    in
    let  prot_json = Proteine.to_yojson prot
     and pnet_json = Petri_net.to_json pnet
    in
    let to_send_json =
      `Assoc
       ["purpose", `String "build_all_from_mol";
        "data", `Assoc ["prot", prot_json;
                        "pnet", pnet_json]] 
    in
    Yojson.Safe.to_string to_send_json
    
  and build_all_from_prot (cgi : Netcgi.cgi) : string =
    let prot_desc = cgi # argument_value "prot_desc" in
    let prot_json = Yojson.Safe.from_string prot_desc in
    print_endline (Yojson.Safe.pretty_to_string prot_json);
    let prot_or_error = Proteine.of_yojson prot_json in
    match prot_or_error with
    | Ok prot ->
       let mol = Molecule.of_proteine prot in
       let mol_json = `String mol in
       let pnet = Petri_net.make_from_mol mol in
       let pnet_json = Petri_net.to_json pnet in
       let to_send_json =
         `Assoc
          ["purpose", `String "build_all_from_prot";
           "data",
           `Assoc ["mol", mol_json; "pnet", pnet_json]]
         
       in
       Yojson.Safe.to_string to_send_json
    | Error s -> 
       "error decoding proteine from json : "^s
      
  and list_acids () : string =
    let json_data =
      `Assoc
       ["purpose", `String "list_acids";
        "data", `List [
                   `Assoc ["type", `String "places";
                           "acids", `List (List.map Acid_types.acid_to_yojson Acid_types.Examples.nodes)];
                   `Assoc ["type", `String "inputs_arcs";
                           "acids", `List (List.map Acid_types.acid_to_yojson Acid_types.Examples.input_arcs)];
                   `Assoc ["type", `String "outputs_arcs";
                           "acids", `List (List.map Acid_types.acid_to_yojson Acid_types.Examples.output_arcs)];
                   `Assoc ["type", `String "extensions";
                           "acids", `List (List.map Acid_types.acid_to_yojson Acid_types.Examples.extensions);]]] in
    Yojson.Safe.to_string json_data
    
  in
  
  let command = cgi # argument_value "command" in
  
  if command = "prot_from_mol"
  then prot_from_mol cgi
  
  else if command = "list_acids"
  then list_acids ()
  
  else if command = "build_all_from_prot"
  then build_all_from_prot cgi

  else if command = "build_all_from_mol"
  then build_all_from_mol cgi
  
  else ("did not recognize command : "^command)
;;
  
  
let handle_req (bact : Bacterie.t) (sandbox : Sandbox.t) env (cgi:Netcgi.cgi)  =
  
  print_endline ("serving GET request :"^(cgi # environment # cgi_query_string));

  List.map (fun x -> print_endline ((x # name)^" : "^(x#value))) (cgi # arguments);
  
  let response = 
    
    if (cgi # argument_exists "container")
    then
      let container = cgi# argument_value "container" in
      if container = "bactery"
      then handle_bact_req bact cgi
      else if container = "sandbox"
      then "sandbox inactive"
      else handle_general_req cgi
          
        
    else handle_general_req cgi
  in
  
  
  print_endline ("preparing to send response :" ^response);
  cgi # set_header ~content_type:"application/json" ();
  cgi # out_channel # output_string response;
  cgi # out_channel # commit_work();
  print_endline ("response sent");
  
;;
  
