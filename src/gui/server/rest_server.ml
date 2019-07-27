open Easy_logging_yojson
let logger = Logging.get_logger "Yaac.Server.Rest"


let logging_handler (cgi: Netcgi.cgi) : Yojson.t =
  let loggername = cgi#argument_value "logger" in
  match cgi#argument_value "level"
        |> Logging.level_of_string with
  | Ok level ->  
     let logger = Logging.get_logger loggername in
     logger#set_level level;
     `String "ok"
  | Error r -> 
     `String r

let table = [
    "/logging/:logger", logging_handler;
    "/builder"        , logging_handler;
  ]

          
          
let make_req_handler simulator sandbox =
  
  Nethttpd_services.dynamic_service
    {
      dyn_handler =
        (fun ev (cgi:Netcgi.cgi)  ->
          let path_full = (cgi # url ())
          and path_begin = (cgi # url ~with_script_name:`None ()) in
          let path = String.sub path_full (String.length path_begin)
                       ((String.length path_full) - String.length path_begin) in
          logger#info "dispatching with %s" path;
          logger#sinfo "Received arguments:";

          List.map (fun e -> Printf.sprintf "%s : %s" e#name e#value) cgi#arguments
          |> List.iter logger#sinfo;


          cgi # set_header ~content_type:"application/json" ~status:`Ok ();
          cgi # out_channel # output_string "ok";
          cgi # out_channel # commit_work ();
          );
      dyn_activation = Nethttpd_services.std_activation `Std_activation_buffered;
      dyn_uri = None;
      dyn_translator = (fun _ -> "");
      dyn_accept_all_conditionals = false
    }
