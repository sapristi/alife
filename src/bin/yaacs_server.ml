open Server
open Reactors
   
let port = ref 1512;;
let host = ref "0.0.0.0";;
let srv_folder = ref "src/gui/js_client";;

         
let speclist = [ ("-port", Arg.Int (fun x -> port := x), "connection port");
                 ("-host", Arg.String (fun x -> host := x), "declared host; must match the adress provided to the client");
                 ("-srv", Arg.String (fun x -> srv_folder := x), "server root folder")]
                 in let usage_msg = "Bact simul serveur" 
                    in Arg.parse speclist print_endline usage_msg;;

    

Logs.set_reporter (Logs.format_reporter ());
Logs.set_level (Some Logs.Info);

  
Web_server.start_srv
  !srv_folder
  (Bact_server.make_req_handler
     (Simulator.make ())
     (Sandbox.of_yojson (Yojson.Safe.from_file "bact.json")))
  (!host, !port) 
  
