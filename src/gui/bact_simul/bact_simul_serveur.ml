open Proteine
open Molecule
open Bacterie
open Petri_net


let get_my_addr () =
  (Unix.gethostbyname(Unix.gethostname())).Unix.h_addr_list.(0) ;;

let make_server server_fun port =
  let my_address = get_my_addr() in
  let sockaddr = Unix.ADDR_INET(my_address, port) in
  let domain = Unix.domain_of_sockaddr sockaddr in
  let sock = Unix.socket domain Unix.SOCK_STREAM 0  in
  print_endline (Unix.string_of_inet_addr my_address);
  Unix.bind sock sockaddr ;
  Unix.listen sock 1;
  let (s, caller) = Unix.accept sock in
  (
    print_endline "connection established";
    let inchan = Unix.in_channel_of_descr s 
    and outchan = Unix.out_channel_of_descr s 
    in server_fun inchan outchan;
    close_in inchan ;
    close_out outchan
  )
;;

let make_bact_interface bact ic oc =
  let gibinitdata () =
    
    print_endline "asking for initdata; sending...";
    
    let json_data = `Assoc
                     ["target", `String "main";
                      "purpose", `String "bactery_init_desc";
                      "data", (Bacterie.to_json bact)] in
    
    let to_send = Yojson.Safe.to_string json_data in

    
    output_string oc to_send;
    flush oc;
    print_endline to_send;
    print_endline "init data sent";

  and give_data_for_mol_exam json_command =
  
    let data = Yojson.Safe.Util.member "data" json_command in
    let mol_str = Yojson.Safe.Util.to_string data in
    let mol = Molecule.string_to_acid_list mol_str in
    let prot = Proteine.from_mol mol 
    and pnet = PetriNet.make_from_mol mol in
    let pnet_json = PetriNet.to_json pnet
    and prot_json = Proteine.to_yojson prot
    in
    let to_send_json =
      `Assoc
       ["target", Yojson.Safe.Util.member "return target" json_command;
        "purpose", `String "prot desc";
        "data",
        `Assoc
         ["prot", prot_json;
          "pnet", pnet_json]
       ] 
    in
    let to_send = Yojson.Safe.to_string to_send_json in
    output_string oc to_send;
    flush oc;
    print_endline to_send;
    print_endline "data for mol exam sent";
    
  and give_prot_desc_for_simul json_command =
    let data = Yojson.Safe.Util.member "data" json_command in
    let mol_str = Yojson.Safe.Util.to_string data in
    let mol = Molecule.string_to_acid_list mol_str in
    let _,pnet = MolMap.find mol bact.Bacterie.molecules
    in
    let pnet_json = PetriNet.to_json pnet in
    
    let to_send_json =
      `Assoc
       ["target", Yojson.Safe.Util.member "return target" json_command;
        "purpose", `String "prot desc";
        "data", pnet_json]
      
    in
    let to_send = Yojson.Safe.to_string to_send_json in
    output_string oc to_send;
    flush oc;
    print_endline to_send;
    print_endline "data for mol simul sent";

  and launch_transition json_command =
    let data_json = Yojson.Safe.Util.member "data" json_command in
    let mol_json = Yojson.Safe.Util.member "mol" data_json
    and trans_id_json = Yojson.Safe.Util.member "trans_id" data_json in
    let mol_str = Yojson.Safe.Util.to_string mol_json
    and trans_id_str = Yojson.Safe.Util.to_string trans_id_json in
    let trans_id = int_of_string trans_id_str in
    
    let mol = Molecule.string_to_acid_list mol_str in
    Bacterie.launch_transition trans_id mol bact;
    let _,pnet = MolMap.find mol bact.Bacterie.molecules
    in
    let pnet_update_json = PetriNet.to_json_update pnet in
    
    let to_send_json =
      `Assoc
       ["target", Yojson.Safe.Util.member "return target" json_command;
        "purpose", `String "updatedata";
        "data", pnet_update_json]
      
    in
    let to_send = Yojson.Safe.to_string to_send_json in
    output_string oc to_send;
    flush oc;
    print_endline to_send;
    print_endline "data for mol simul sent";
  in

  (* try *)
  while true do
    let s = input_line ic in
    
    print_endline "received message, printing";
    print_endline s;
    print_endline "end of message";
    
    let json_message = Yojson.Safe.from_string s in
    let command = Yojson.Safe.to_string (Yojson.Safe.Util.member "command" json_message) in  
    (
      
      if command = "\"gibinitdata\""
      then gibinitdata ()
      
      else if command = "\"give data for mol exam\""
      then give_data_for_mol_exam json_message

      else if command = "\"give prot desc for simul\""
      then give_prot_desc_for_simul json_message 

      else if command = "\"launch transition\""
      then launch_transition json_message
      
    )
  done
(*  with _ -> Printf.printf "End of text\n" ; flush stdout ; exit 0 ;;*)
  
let go_bact_interface bact = 
   Unix.handle_unix_error make_server (make_bact_interface bact) 1512;;

