(* * simulation server *)

(* ** preamble*)
open Proteine
open Molecule
open Bacterie
open Petri_net

   
let handle_req bact env (cgi:Netcgi.cgi)  =

(* *** gibinitdata *)
(* sends the initial simulation data, hardcoded in the program *)
  let gibinitdata () =
    let json_data = `Assoc
                     ["target", `String "main";
                      "purpose", `String "bactery_init_desc";
                      "data", (Bacterie.to_json bact)] in
    
    Yojson.Safe.to_string json_data

(* *** give_data_for_mol_exam *)
(* sends the proteine and pnet data associated to a given mol *)
  and give_data_for_mol_exam (cgi:Netcgi.cgi)  =
    let mol_desc = cgi # argument_value "mol_desc" in
    let mol = Molecule.string_to_acid_list mol_desc in
    let prot = Proteine.from_mol mol 
    and pnet = PetriNet.make_from_mol mol in
    let pnet_json = PetriNet.to_json pnet
    and prot_json = Proteine.to_yojson prot
    in
    let to_send_json =
      `Assoc
       ["purpose", `String "prot desc";
        "data",
        `Assoc
         ["prot", prot_json;
          "pnet", pnet_json]
         ] 
    in
    Yojson.Safe.to_string to_send_json
      

(* *** give_prot_desc_for_simul *)
(* sends the pnet data associated to a given molThe pnet is created  *)
(* outside of the bactery, to simulates its transitions outside of  *)
(* the main simulation *)
  and give_prot_desc_for_simul (cgi:Netcgi.cgi) =
    let mol_str = cgi # argument_value "data" in
    let mol = Molecule.string_to_acid_list mol_str in
    let _,pnet = MolMap.find mol bact.Bacterie.molecules
    in
    let pnet_json = PetriNet.to_json pnet in
    
    let to_send_json =
      `Assoc
     ["purpose", `String "prot desc";
      "data", pnet_json]
      
    in
    Yojson.Safe.to_string to_send_json


(* *** launch_transition *)
(* launches a given transition of a pnet in the bacteria *)
  and launch_transition (cgi:Netcgi.cgi) =
    let mol_desc = cgi # argument_value  "mol_desc" 
    and trans_id_str = cgi # argument_value "trans_id" in
    let trans_id = int_of_string trans_id_str in
    
    let mol = Molecule.string_to_acid_list mol_desc in
    Bacterie.launch_transition trans_id mol bact;
    let _,pnet = MolMap.find mol bact.Bacterie.molecules
    in
    let pnet_update_json = PetriNet.to_json_update pnet in
    
    let to_send_json =
      `Assoc
       ["purpose", `String "updatedata";
        "data", pnet_update_json]
      
    in
    Yojson.Safe.to_string to_send_json

(* *** gen_from_prot *)
(* generates the molecule and the pnet associated with a proteine *)
  and gen_from_prot (cgi:Netcgi.cgi) =
    let prot_desc = cgi # argument_value "prot_desc" in
    let prot_json = Yojson.Safe.from_string prot_desc in
    let prot_or_error = Proteine.of_yojson prot_json in
    match prot_or_error with
  | Ok prot ->
     let mol = Proteine.to_molecule prot in
     let mol_json = `String (Molecule.to_string mol) in
     let pnet = PetriNet.make_from_mol mol in
     let pnet_json = PetriNet.to_json pnet in
     let to_send_json =
       `Assoc
        ["purpose", `String "from prot";
         "data",
         `Assoc ["mol", mol_json; "pnet", pnet_json]]
       
     in
     Yojson.Safe.to_string to_send_json
  | Error s -> 
     "error : "^s

(* *** gen_from_mol *)
(* generates the proteine and the pnet associated with a molecule *)
and gen_from_mol (cgi:Netcgi.cgi) =
  let mol_str = cgi # argument_value "mol_desc" in
  let mol = Molecule.string_to_acid_list mol_str in

  let prot = Proteine.from_mol mol in
  let prot_json = Proteine.to_yojson prot in
  let pnet = PetriNet.make_from_mol mol in
  let pnet_json = PetriNet.to_json pnet in
  let to_send_json =
    `Assoc
     ["purpose", `String "from mol";
      "data",
      `Assoc ["prot", prot_json; "pnet",pnet_json]]
       
  in
  Yojson.Safe.to_string to_send_json 

(* *** make_reactions *)
(* evaluates possibles reactions in the simulation *)
and make_reactions () =
  Bacterie.make_reactions bact;
  let json_data = `Assoc
                   ["purpose", `String "bactery_update_desc";
                    "data", (Bacterie.to_json bact)] in  
  Yojson.Safe.to_string json_data
  
(* *** main *)
  in

  print_endline (cgi # environment # cgi_query_string); 
  
  let command = cgi # argument_value "command" in

  let response = 
  
    if command = "gibinitdata"
    then gibinitdata ()
    
    else if command = "give data for mol exam"
    then give_data_for_mol_exam cgi
    
    else if command = "give prot desc for simul"
    then give_prot_desc_for_simul cgi
    
    else if command = "launch transition"
    then launch_transition cgi
    
    else if command = "gen from mol"
    then gen_from_mol cgi
    
    else if command = "gen from prot"
    then gen_from_prot cgi
    
    else if command = "make reactions"
    then make_reactions ()
          
    
    else ("did not recognize command : "^command)
  in
  cgi # out_channel # output_string response;
  cgi # out_channel # commit_work()
;;
