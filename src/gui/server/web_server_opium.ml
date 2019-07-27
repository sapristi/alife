open Opium.Std
open Easy_logging_yojson

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
  logger#debug "Serving file %s" full_path;
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
and key = Opium_kernel__Hmap0.Key.create ("c", (fun _ -> Atom "c"));;

let tag_request =
  let filter : 
        (Opium_kernel__Rock.Request.t, Opium_kernel__Rock.Response.t)
          Opium_kernel__Rock.Filter.simple  = fun handler req -> 
    let env = Opium_kernel__Hmap0.add key (string_of_int !req_counter) req.env in
    req_counter := !req_counter + 1;
    let req = {req with env=env} in
    handler req
  in
  Rock.Middleware.create ~name:"tag request" ~filter

let get_tag env =
  Opium_kernel__Hmap0.find_exn key env

let log_in =
  let filter : (Opium_kernel__Rock.Request.t, Opium_kernel__Rock.Response.t)
                 Opium_kernel__Rock.Filter.simple  = fun handler req -> 
    let resource = req.request.resource
    and meth = Cohttp.Code.sexp_of_meth req.request.meth |> Base.Sexp.to_string_hum
    in
    logger#trace ~tags:[get_tag req.env] "Serving %s request at %s" meth resource;
    logger#debug "Request body: %s" (Lwt_main.run (Cohttp_lwt.Body.to_string req.body));
    handler req
  in
  Rock.Middleware.create ~name:"Log in" ~filter

let log_out =
  let filter : (Opium_kernel__Rock.Request.t, Opium_kernel__Rock.Response.t)
                 Opium_kernel__Rock.Filter.simple  = fun handler req -> 
    let response = Lwt.bind (Lwt.return req) handler in 
    response
    |> Lwt_main.run
    |> Response.code
    |> Cohttp.Code.string_of_status
    |> logger#trace ~tags:[get_tag req.env] "Response: %s";
    handler req
  in
  Rock.Middleware.create ~name:"Log out" ~filter


let start_srv port files_prefix =
  App.empty
  |> App.port port
  |> middleware tag_request
  |> middleware log_in
  |> get "**" (fun x -> serve_file files_prefix x.request.resource)
  |> get "/api/" (fun x -> `String "api ok" |> respond')
  |> middleware log_out
  |> App.start
  |> Lwt_main.run

