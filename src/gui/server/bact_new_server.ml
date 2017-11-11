(* * simulation server *)

(* ** preamble*)
open Proteine
open Molecule
open Bacterie
open Petri_net
open Sandbox

let get_pnet_from_container
      mol
      (bact : Bacterie.t)
      (sb : SandBox.t)
      (cgi:Netcgi.cgi) =

  if cgi # argument_exists "container"
  then 
    if cgi # argument_value "container" = "bacterie"
    then Bacterie.get_pnet_from_mol mol bact
    else if cgi # argument_value "container" = "sandbox"
    then SandBox.get_pnet_from_mol mol sb
    else failwith "la requête ne contient pas de conteneur de molécule valide"
  else failwith "la requête ne contient pas de conteneur de molécule" 
;;

  
let handle_req (bact : Bacterie.t) (sandbox : SandBox.t) env (cgi:Netcgi.cgi)  =

(* *** prot_from_mol *)
  let prot_from_mol (cgi:Netcgi.cgi)  =
    
    let mol_desc = cgi # argument_value "mol_desc" in
    let mol = Molecule.string_to_acid_list mol_desc in
    let prot = Proteine.from_mol mol in
    let prot_json = Proteine.to_json prot
    in
    let to_send_json =
      `Assoc
       ["purpose", `String "prot_from_mol";
        "data", `Assoc ["prot", prot_json]] 
    in
    Yojson.Safe.to_string to_send_json

(* *** pnet_from_mol *) 

  and pnet_from_mol (cgi:Netcgi.cgi)  =

    print_endline ("serving pnet_from_mol with mol :"
                  ^(cgi # argument_value "mol_desc"));
    let mol_desc = cgi # argument_value "mol_desc" in
    let mol = Molecule.string_to_acid_list mol_desc in
    let pnet = get_pnet_from_container mol bact sandbox cgi
      
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

  and get_bact_elements () =
     let json_data = `Assoc
                     ["purpose", `String "bact_elements";
                      "data", (Bacterie.to_json bact)] in
    
    Yojson.Safe.to_string json_data

  and get_sandbox_elements () =
     let json_data = `Assoc
                     ["purpose", `String "sandbox_elements";
                      "data", (SandBox.to_json sandbox)] in
    
    Yojson.Safe.to_string json_data

  and make_reactions () =
    Bacterie.make_reactions bact;
    let json_data = `Assoc
                     ["purpose", `String "bactery_update_desc";
                      "data", (Bacterie.to_json bact)] in  
    Yojson.Safe.to_string json_data

  and list_acids () =
    let json_data = `Assoc
                     ["places", `List (List.map Proteine.acid_to_json AcidExamples.nodes);
                      "transition_inputs", `List (List.map Proteine.acid_to_json AcidExamples.transition_inputs);
                      "transition_outputs", `List (List.map Proteine.acid_to_json AcidExamples.transition_outputs);
                      "extensions", `List (List.map Proteine.acid_to_json AcidExamples.extensions);] in
    Yojson.Safe.to_string json_data

  and commit_token_edit  (cgi : Netcgi.cgi) =
    ""
    
    
  in

  
  print_endline ("serving GET request :"^(cgi # environment # cgi_query_string));
  
  let command = cgi # argument_value "command" in
  
  let response = 
    
    if command = "prot_from_mol"
    then prot_from_mol cgi
    
    else if command = "pnet_from_mol"
    then pnet_from_mol cgi
    
    else if command = "get_bact_elements"
    then get_bact_elements ()
    
    else if command = "get_sandbox_elements"
    then get_sandbox_elements ()
    
    else if command = "make_reactions"
    then make_reactions ()
    
    else if command = "list_acids"
    then list_acids ()
    
    else if command = "commit token edit"
    then commit_token_edit cgi
      
    else ("did not recognize command : "^command)
    in
    
    
    print_endline ("preparing to send response :" ^response);
    cgi # out_channel # output_string response;
    cgi # out_channel # commit_work();
    print_endline ("response sent");

;;
