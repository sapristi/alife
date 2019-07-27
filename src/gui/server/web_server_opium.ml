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

let serve_file prefix path =
  logger#debug "Serving %s at %s" path prefix;
  let ext = Filename.extension path
  and full_path = (prefix^path)in
  logger#debug "ext: %s" ext;
  let (res_body, headers, code) = match List.find_opt (fun (ext',_) -> ext = ext') config with
    | None -> `String "not found", Cohttp.Header.init_with "Content-Type" "text/plain", `Not_found
    | Some (_, content_type ) ->
       if Sys.file_exists full_path
       then
         let data = read_whole_file full_path in
         `String data, Cohttp.Header.init_with "Content-Type" content_type, `OK
       else
         `String "not found", Cohttp.Header.init_with "Content-Type" "text/plain", `Not_found
    
  in respond' ~headers:headers ~code:code res_body
    
let start_srv port files_prefix =
  App.empty
  |> App.port port
  |> get "**" (fun x -> serve_file files_prefix x.request.resource)
  |> get "/api/" (fun x -> `String "api ok" |> respond')
  |> App.start
  |> Lwt_main.run

