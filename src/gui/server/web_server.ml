
(* * web_server *)

open Nethttp
open Nethttp.Header
open Nethttpd_types
open Nethttpd_kernel
open Nethttpd_services
open Nethttpd_engine
open Nethttpd_types
open Nethttpd_reactor;;


let fs_spec =
  { file_docroot = (Sys.getenv "HOME")^("/Documents/projets/alife/src/gui/js_client");
    file_uri = "/";
    file_suffix_types = [ "txt", "text/plain";
			  "html", "text/html";
                          "css", "text/css";
                          "js", "text/js"];
    file_default_type = "application/octet-stream";
    file_options = [ `Enable_gzip;
		     `Enable_listings (simple_listing ?hide:None);
		     `Enable_index_file ["index.html"]
		   ]
  }

  
let get_my_addr () =
  (Unix.gethostbyname(Unix.gethostname())).Unix.h_addr_list.(0) ;;

   
let make_srv req_processor (conn_attr : (string * int)) =
  let (host_name, port) = conn_attr in
  host_distributor
    [ default_host ~pref_name:host_name ~pref_port:port (),
      uri_distributor
        [ "*", (options_service());
          "/", (file_service fs_spec);
          "/sim_commands/", (dynamic_service
                               { dyn_handler = req_processor;
                                 dyn_activation = std_activation `Std_activation_buffered;
                                 dyn_uri = None;
                                 dyn_translator = (fun _ -> "");
                                 dyn_accept_all_conditionals = false
                            })
        ]
    ] 


let serve_connection ues fd req_processor (conn_attr)=
  (* cgi config to change if diffent input methods are needed *)
  let custom_cgi_config =Netcgi.default_config  in
  let config =
    new Nethttpd_engine.modify_http_engine_config
      ~config_input_flow_control:true
      ~config_output_flow_control:true
      ~modify_http_processor_config:
      (new Nethttpd_reactor.modify_http_processor_config
         ~config_cgi:custom_cgi_config)
    
      Nethttpd_engine.default_http_engine_config in
  let pconfig = 
    new Nethttpd_engine.buffering_engine_processing_config in

  Unix.set_nonblock fd;

  ignore(Nethttpd_engine.process_connection
           config
           pconfig
           fd
           ues
           (make_srv req_processor conn_attr))
;;

let rec accept req_processor (conn_attr) ues srv_sock_acc =
  (* This function accepts the next connection using the [acc_engine]. After the   
   * connection has been accepted, it is served by [serve_connection], and the
   * next connection will be waited for (recursive call of [accept]). Because
   * [server_connection] returns immediately (it only sets the callbacks needed
   * for serving), the recursive call is also done immediately.
   *)
  let acc_engine = srv_sock_acc # accept() in
  Uq_engines.when_state
    ~is_done:(fun (fd,fd_spec) ->
      if srv_sock_acc # multiple_connections then (
        serve_connection ues fd req_processor conn_attr;
        accept req_processor conn_attr ues srv_sock_acc
      ) else
        srv_sock_acc # shut_down())
    ~is_error:(fun _ -> srv_sock_acc # shut_down())
    acc_engine;
;;




let start_srv req_processor (conn_attr) =
  
  let (host_name, port) = conn_attr in
  
  let ues = Unixqueue.create_unix_event_system () in
  let opts = { Uq_server.default_listen_options with
               Uq_server.lstn_backlog = 20;
               Uq_server.lstn_reuseaddr = true } in
  let lstn_engine =
    Uq_server.listener
      (`Socket(`Sock_inet(Unix.SOCK_STREAM, Unix.inet_addr_any, port) ,opts)) ues in
  Uq_engines.when_state ~is_done:(accept req_processor conn_attr ues) lstn_engine;
  
  Printf.printf "Listening as %s on port %i\n" host_name port;
  flush stdout;
  
  Unixqueue.run ues
;;

(*
let print_req env (cgi:Netcgi.cgi) =
  let rec print_arg_list (l : Netcgi.cgi_argument list) =
    match l with
    | h::t -> (h#name )^" "^(h#value)^(print_arg_list t)
    | [] -> ""
  in
  
  cgi # output # output_string "<html><body>\n";
  cgi # output # output_string (print_arg_list cgi#arguments);
  cgi # output # output_string "</body></html>\n";
  cgi # output # commit_work()
;;

 *)
  (*  start_srv print_req 8765;; *)
