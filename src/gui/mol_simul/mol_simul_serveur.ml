open Proteine
open Molecule
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




let make_prot_interface (pnet : PetriNet.t) ic oc  =
  let p = ref pnet in 
  try while true do
      let s = input_line ic in
      let json_command = Yojson.Basic.from_string s in
      let command = json_command |> Yojson.Basic.Util.member "command" |> Yojson.Basic.Util.to_string in 
      (
	print_endline s;
	if command = "gibinitdata"
	then
	  (
	    print_endline "asking for initdata; sending...";
	    let json_data = `Assoc ["initdata", (PetriNet.to_json !p)] in
	    let to_send = Yojson.Safe.to_string json_data in

            
            print_endline "sending data ...";
            print_endline to_send;
            
            output_string oc to_send;
	    flush oc;
	    print_endline "initdata sent";
	  )
	else if command = "gibupdatedata"
	then
	  (
	    print_endline "asking for updatedata; sending...";
	    let json_data = `Assoc ["updatedata", (PetriNet.to_json_update !p)] in 
	    let to_send = Yojson.Safe.to_string json_data in

            print_endline "sending update data ...";
            print_endline to_send;
                        
	    output_string oc to_send;
	    flush oc;
	    print_endline "updatedata sent";
	  )
	else if command = "launch"
	then
	  (
	    print_endline "asked to launch transition";
	    let tId = int_of_string (Bytes.to_string (json_command |> Yojson.Basic.Util.member "arg" |> Yojson.Basic.Util.to_string)) in

            if tId >= 0
            then
              begin
                print_endline("launching transition "^(string_of_int tId)); 
	        PetriNet.launch_transition tId !p;
	        PetriNet.update_launchables !p;
	        print_endline (Yojson.Safe.to_string (PetriNet.to_json_update !p));
	        
	        let json_data = `Assoc ["transition_launch", `Bool true] in
	        let to_send = Yojson.Safe.to_string json_data in
	        output_string oc to_send;
	        flush oc;
	        print_endline "transition launch report sent"
              end
            else
              print_endline("no available transition")
	  )
	else if command = "new_mol"
	then
	  (
	    print_endline "received new prot, decoding..."; 
	    try 
	      let new_prot_str = Bytes.to_string (json_command |> Yojson.Basic.Util.member "arg" |> Yojson.Basic.Util.to_string) in 
	      print_endline new_prot_str;
              let new_mol_json =  Yojson.Safe.from_string new_prot_str in

              print_endline  (Yojson.Safe.to_string new_mol_json);
              
	      let new_prot = Proteine.of_yojson new_mol_json in
	      match new_prot with
              | Ok prot ->
	         (
	           p := PetriNet.make_from_prot prot;
	           print_endline "new mol decoded, sending new initdata to client...";
	           let json_data = `Assoc ["initdata", (PetriNet.to_json !p)] in
	           let to_send = Yojson.Safe.to_string json_data in
	           output_string oc to_send;
	           flush oc;
	           print_endline "initdata sent"
	         )
	      | Error s -> print_endline ("error : "^ s)
                          
	    with _ -> print_endline "problem decoding molecule"
	  )
	else if command = "quit"
	then
	  (
	    print_endline "received quit command; exiting";
	    flush stdout ; exit 0 ;
	  )
	else print_endline ("unknown command: "^s)
      );
      
    done
  with _ -> Printf.printf "End of text\n" ; flush stdout ; exit 0 ;;


let go_prot_interface prot = 
   Unix.handle_unix_error make_server (make_prot_interface prot) 1512;;


