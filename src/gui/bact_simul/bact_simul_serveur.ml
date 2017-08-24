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
    print_endline "init data sent";

  and give_prot_desc_for_exam json_command =
  
    let data = Yojson.Safe.Util.member "data" json_command in
    let prot_or_error = Proteine.of_yojson data in
    match prot_or_error with
    | Ok prot -> 
       let pnet = PetriNet.make_from_prot prot in
       let pnet_json = PetriNet.to_json pnet in
       
       let to_send_json =
         `Assoc
          ["target", Yojson.Safe.Util.member "return target" json_command;
           "purpose", `String "prot desc";
           "data", pnet_json]
         
       in
       output_string oc (Yojson.Safe.to_string to_send_json);
       flush oc;
       print_endline "prot data sent";
       
    | Error s -> print_endline ("error : "^ s)

  and give_prot_desc_for_simul json_command =
    let data = Yojson.Safe.Util.member "data" json_command in
    let mol_str = Yojson.Safe.Util.to_string data in
    let mol = Molecule.string_to_acid_list mol_str in
    let _,pnet = MolMap.find mol bact.molecules
    in
    let pnet_json = PetriNet.to_json pnet in
    
    let to_send_json =
      `Assoc
       ["target", Yojson.Safe.Util.member "return target" json_command;
        "purpose", `String "prot desc";
        "data", pnet_json]
      
    in
    
    output_string oc (Yojson.Safe.to_string to_send_json);
    flush oc;
    print_endline "prot data sent";
  in

  (* try *)
  while true do
    let s = input_line ic in
    
    print_endline "received message, printing";
    print_endline s;
    print_endline "end of message";
    
    let json_command = Yojson.Safe.from_string s in
    let command = Yojson.Safe.to_string (Yojson.Safe.Util.member "command" json_command) in  
    (
      print_endline command;
      if command = "\"gibinitdata\""
      then gibinitdata ()
      
      else if command = "\"give prot desc for exam\""
      then give_prot_desc_for_exam json_command

      else if command = "\"give prot desc for simul\""
      then give_prot_desc_for_simul json_command 

      else if command = "\"launch transition\""
      then
        (
          print_endline "todo"
        )
      
    )
  done
(*  with _ -> Printf.printf "End of text\n" ; flush stdout ; exit 0 ;;*)
  
let go_bact_interface bact = 
   Unix.handle_unix_error make_server (make_bact_interface bact) 1512;;

