open Server
open Reactors
   
let port = ref 1512;;
let host = ref "localhost";;
         
  
         
let speclist = [ ("-port", Arg.Int (fun x -> port := x), "connection port");
                 ("-host", Arg.String (fun x -> host := x), "declared host; must match the adress provided to the client")]
    in let usage_msg = "Bact simul serveur" 
       in Arg.parse speclist print_endline usage_msg;;

    

Logs.set_reporter (Logs.format_reporter ());
Logs.set_level (Some Logs.Info);

  
Web_server.start_srv (Bact_server.make_req_handler
                        (Simulator.make ())
                        (Sandbox.of_yojson (Yojson.Safe.from_file "bact.json")))
                     (!host, !port) 
  
