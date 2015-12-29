open Proteine
open Types.MyMolecule
  
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




let make_prot_interface (prot : Proteine.t) ic oc  =
  
  try while true do
      let s = input_line ic in
      (
	if s = "gibinitdata"
	then
	  (
	    print_endline "asking for initdata";
	    let to_send = (Yojson.Safe.to_string (Proteine.to_json prot)) in
	    print_endline to_send;
	    output_string oc to_send;
	    flush oc;
	  (*	    print_string to_send*)
	  )
	else if s = "gibdotdata"
	then
	  (
	  )
	else print_endline ("unknown command: "^s)
      );
      
    done
  with _ -> Printf.printf "End of text\n" ; flush stdout ; exit 0 ;;


let go_prot_interface prot = 
   Unix.handle_unix_error make_server (make_prot_interface prot) 1512;;


