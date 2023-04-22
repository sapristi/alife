open Easy_logging_yojson
open Lwt.Infix

let logger = Logging.get_logger "Yaac.Server"

(* (\* unused *\) *)
(* module FileServer = struct *)
(*   let read_whole_file filename = *)
(*     let ch = open_in filename in *)
(*     let s = really_input_string ch (in_channel_length ch) in *)
(*     close_in ch; *)
(*     s *)

(*   let config = [ ".txt", "text/plain"; *)
(* 			           ".html", "text/html"; *)
(*                  ".css", "text/css"; *)
(*                  ".js", "text/javascript"; *)
(*                  ".ico", "img/ico"] *)

(*   let response_not_found = `String "not found", Utils.Resp.default_header, `Not_found *)

(*   let serve_file prefix path = *)
(*     let ext = Filename.extension path *)
(*     and full_path = (prefix^path) in *)
(*     logger#trace "Serving file %s" full_path; *)
(*     let (res_body, headers, code) = match List.find_opt (fun (ext',_) -> ext = ext') config with *)
(*       | None -> response_not_found *)
(*       | Some (_, content_type ) -> *)
(*         if Sys.file_exists full_path *)
(*         then *)
(*           let data = read_whole_file full_path in *)
(*           `String data,  ["Content-Type", content_type], `OK *)
(*         else *)
(*           response_not_found *)
(*     in Opium.Response.of_plain_text ~status:code res_body |> Opium.Response.add_headers headers *)
(* end *)


let req_counter = ref 0

(* let filter_options = *)
(*   let filter : (Opium_kernel__Rock.Request.t, Opium_kernel__Rock.Response.t) *)
(*       Opium.Filter.simple  = fun handler req -> *)
(*     ( *)
(*       match req.request.meth with *)
(*       | `OPTIONS -> let headers = Cohttp.Header.of_list *)
(*                         [("Access-Control-Allow-Origin","*"); *)
(*                          ("Access-Control-Allow-Methods", "GET, PUT, POST, DELETE")] in *)
(*         Rock.Response.create ~headers:headers () |> Lwt.return *)
(*       | _ -> handler req *)
(*     ) in *)
(*   Rock.Middleware.create ~name:"options filter" ~filter *)

let add_cors_header =
  let filter : (Opium.Request.t, Opium.Response.t)
      Rock.Filter.simple  = fun handler req ->
    (
      let handler' = fun req ->
        let response =
          Lwt.bind (Lwt.return req) handler in
        (
          response >|= (fun response ->
              Opium.Response.add_header ("Access-Control-Allow-Origin", "*") response
            )
        ) in
      handler' req) in
  Rock.Middleware.create ~name:"cors header" ~filter

let log_in_out =
  let filter : (Opium.Request.t, Opium.Response.t)
      Rock.Filter.simple  = fun handler req ->
    let c = string_of_int (!req_counter) in
    (
      req_counter := !req_counter +1;
      let target = req.target
      and meth = Opium.Method.to_string req.meth
      in
      logger#trace ~tags:[c] "Serving %s request at %s" meth target;
      let handler' = fun req ->
        try%lwt
          let response = handler req in
          (
            response
            >|= (fun resp -> resp.status)
            >|= Opium.Status.to_string
            >|= logger#trace ~tags:[c] "Response: %s"
            (* >|= fun () -> *)
            (* response >|= Response.headers >|= Cohttp.Header.to_string *)
            (* >|= logger#debug ~tags:[c] "Headers: %s"; *)
            (* response *)
            (* >|= (fun r -> r.body)
             * >>= Cohttp_lwt.Body.to_string
             * >|= logger#debug ~tags:[c] "Body: %s" *)
          )
          >>= ( fun _ -> response)
        with
        | _ as e ->
          let backtrace = Printexc.get_backtrace () in
          logger#error ~tags:[c] "An error happened while treating the request %s:%s:\n%s\n%s"
            meth target
            backtrace
            (Printexc.to_string e);
          `Error (Printf.sprintf "An error happened while treating the request at %s" target)
          |> Lwt.return >|= Utils.Resp.handle

      in
      handler' req
    )
  in
  Rock.Middleware.create ~name:"Log in out" ~filter

let index_resources = [
  "/";
  (* "/sandbox"; "/sandbox/"; "/molbuilder"; "/molbuilder/"; "/simulator"; "/simulator/" *)
]
let index_redirect =
  let filter : (Opium.Request.t, Opium.Response.t)
      Rock.Filter.simple  = fun handler req ->
    if List.mem req.target index_resources
    then
      let target' = Filename.concat req.target "index.html" in
      logger#debug "Redirecting %s to %s" req.target target';
      let req' = {req with target = target'} in
      handler req'
    else
      handler req
  in
  Rock.Middleware.create ~name:"Index redirect" ~filter
let pages = [
  "/"; "/sandbox"; "/sandbox/"; "/molbuilder"; "/molbuilder/"; "/simulator"; "/simulator/"
  ; "/logs"
]
let single_index_redirect =
  let filter : (Opium.Request.t, Opium.Response.t)
      Rock.Filter.simple  = fun handler req ->
    logger#debug "Requesting resource %s" req.target;
    if List.mem req.target pages
    then
      let target' = "index.html" in
      logger#debug "Redirecting %s to %s" req.target target';
      let req' = {req with target = target'} in
      handler req'
    else
      handler req
  in
  Rock.Middleware.create ~name:"Index redirect" ~filter

let format_meth meth =
  if meth == Opium.App.get
  then "GET   "
  else if meth == Opium.App.post
  then "POST  "
  else if meth == Opium.App.put
  then "PUT   "
  else if meth == Opium.App.delete
  then "DELETE"
  else "unknown"


let run port files_prefix routes =
  logger#info "Webserver running at http://localhost:%i" port;
  Opium.App.empty
  |> Opium.App.port port
  (* |> Opium.App.middleware filter_options *)
  |> Opium.App.middleware add_cors_header
  |> Opium.App.middleware log_in_out
  (* |> get "**" (fun x -> serve_file files_prefix x.request.resource) *)
  |> Opium.App.get "/ping" (fun x -> Opium.Response.of_plain_text "ok" |> Lwt.return)
  |> List.fold_right (fun (meth, route,f) x ->
      logger#info "%s :: %s" (format_meth meth) route;
      (meth route (fun req -> f req >|= Utils.Resp.handle))
        x
    )
    routes
  (* |> Opium.App.middleware single_index_redirect *)
  (* |> Opium.App.middleware (Opium.Middleware.static_unix ~local_path:files_prefix ~uri_prefix:"/" ()) *)
  |> Opium.App.start
