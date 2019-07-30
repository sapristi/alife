open Opium.Std
open Easy_logging_yojson
open Lwt.Infix

let logger = Logging.make_logger "Server" Debug [Cli Debug] ;;

let read_whole_file filename =
  let ch = open_in filename in
  let s = really_input_string ch (in_channel_length ch) in
  close_in ch;
  s

let config = [ ".txt", "text/plain";
			         ".html", "text/html";
               ".css", "text/css";
               ".js", "text/javascript";
               ".ico", "img/ico"];;

let response_not_found = `String "not found", Cohttp.Header.init (), `Not_found

let serve_file prefix path =
  let ext = Filename.extension path
  and full_path = (prefix^path)in
  logger#trace "Serving file %s" full_path;
  let (res_body, headers, code) = match List.find_opt (fun (ext',_) -> ext = ext') config with
    | None -> response_not_found
    | Some (_, content_type ) ->
       if Sys.file_exists full_path
       then
         let data = read_whole_file full_path in
         `String data, Cohttp.Header.init_with "Content-Type" content_type, `OK
       else
         response_not_found
  in respond' ~headers:headers ~code:code res_body


let req_counter = ref 0

let log_in_out = 
 let filter : (Opium_kernel__Rock.Request.t, Opium_kernel__Rock.Response.t)
                 Opium_kernel__Rock.Filter.simple  = fun handler req -> 
   let c = string_of_int (!req_counter) in
   (
     req_counter := !req_counter +1;
     let resource = req.request.resource
     and meth = Cohttp.Code.sexp_of_meth req.request.meth |> Base.Sexp.to_string_hum
     in
     logger#trace ~tags:[c] "Serving %s request at %s" meth resource;
     let handler' = fun req ->
       try%lwt
         let response =
         Lwt.bind (Lwt.return req) handler in
         (
           response
           >|= Response.code
           >|= Cohttp.Code.string_of_status
           >|= logger#trace ~tags:[c] "Response: %s";
         )
         >>= ( fun () -> response)
       with
       | _ as e ->
         logger#error ~tags:[c] "An error happened while treating the request:%s\n%s"
           (Printexc.get_backtrace ())
           (Printexc.to_string e);
         `String "error" |> respond'
         

     in
     handler' req
   )
 in
 Rock.Middleware.create ~name:"Log in out" ~filter

let start_srv port files_prefix routes =
  App.empty
  |> App.port port
  |> middleware log_in_out
  |> get "**" (fun x -> serve_file files_prefix x.request.resource)
  |> routes
  |> App.start
  |> Lwt_main.run

