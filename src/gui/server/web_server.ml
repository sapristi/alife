
(* * web_server *)

open Nethttp
open Nethttp.Header
open Nethttpd_types
open Nethttpd_kernel
open Nethttpd_services
open Nethttpd_engine
open Nethttpd_types
open Nethttpd_reactor
open Local_libs
open Easy_logging
let logger = Logging.make_logger "Yaac.Server"
               (Some Info)
               [Cli Debug]
           

let fs_spec file_root =
  { file_docroot = file_root;
    file_uri = "/";
    file_suffix_types = [ "txt", "text/plain";
			  "html", "text/html";
                          "css", "text/css";
                          "js", "text/js";
                          "ico", "img/ico"];
    file_default_type = "application/octet-stream";
    file_options = [ `Enable_gzip;
		     `Enable_listings (simple_listing ?hide:None);
		     `Enable_index_file ["index.html"]
		   ]
  }

  
let get_my_addr () =
  (Unix.gethostbyname(Unix.gethostname())).Unix.h_addr_list.(0) 

   
let make_srv file_root req_processor (conn_attr : (string * int)) =
  let (host_name, port) = conn_attr in
  host_distributor
    [ default_host ~pref_name:host_name ~pref_port:port (),
      uri_distributor
        [ "*", (options_service());
          "/", (file_service (fs_spec file_root));
          "/sim_commands/", req_processor;
        ]
    ] 


let serve_connection ues fd srv =
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
           srv)


let rec accept srv ues srv_sock_acc =
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
        serve_connection ues fd srv;
        accept srv ues srv_sock_acc
      ) else
        srv_sock_acc # shut_down())
    ~is_error:(fun _ -> srv_sock_acc # shut_down())
    acc_engine



let start_srv file_root req_processor (conn_attr) =
  
  let (host_name, port) = conn_attr in
  
  let ues = Unixqueue.create_unix_event_system () in
  let opts = { Uq_server.lstn_backlog = 20;
               Uq_server.lstn_reuseaddr = true } in
  let lstn_engine =
    Uq_server.listener
      (`Socket(`Sock_inet(Unix.SOCK_STREAM, Unix.inet_addr_any, port) ,opts)) ues 
  and srv = make_srv file_root req_processor conn_attr in
  Uq_engines.when_state ~is_done:(accept srv ues) lstn_engine;

  Printf.sprintf "Listening as %s on port %i\n" host_name port
  |> logger#info;
  
  Unixqueue.run ues
