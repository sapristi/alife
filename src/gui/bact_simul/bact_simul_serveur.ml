open Proteine
open Molecule
open Bacterie
   
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

            
	    let json_data = `Assoc ["bactery_init_desc", (Bacterie.to_json bact)] in
	    let to_send = Yojson.Safe.to_string json_data in

            
            print_endline "sending data ...";
            print_endline to_send;
            
            output_string oc to_send;
	    flush oc;
	    print_endline "initdata sent";
	  )
      )
      done
  with _ -> Printf.printf "End of text\n" ; flush stdout ; exit 0 ;;

let go_bact_interface bact = 
   Unix.handle_unix_error make_server (make_bact_interface bact) 1512;;

