open Server
open Reactors
open Local_libs
let () = Printexc.record_backtrace true;;
let port = ref 1512;;
let host = ref "0.0.0.0";;
let srv_folder = ref "_build/default/src/gui/js_client";;

         
let speclist = [ ("-port", Arg.Int (fun x -> port := x), "connection port");
                 ("-host", Arg.String (fun x -> host := x), "declared host; must match the adress provided to the client");
                 ("-srv", Arg.String (fun x -> srv_folder := x), "server root folder")]
                 in let usage_msg = "Bact simul serveur" 
                    in Arg.parse speclist print_endline usage_msg;;

let format_dummy : Logger.Formatter.t = fun item -> item.msg in
    let handler = Logger.Handler.make_file_handler Logger.Debug "stats" in
    let stats_reporter = Logger.get_logger "reacs_stats" in
    stats_reporter#add_handler handler;
    stats_reporter#set_level (Some Debug);
    Logger.Handler.set_formatter handler format_dummy;
    stats_reporter#info "ireactants areactants transitions grabs breaks  picked_dur treated_dur actions_dur";;
    
Web_server.start_srv
  !srv_folder
  (Bact_server.make_req_handler
     (Simulator.make ())
     (Sandbox.of_yojson (Yojson.Safe.from_file "bact.json")))
  (!host, !port) 
  
