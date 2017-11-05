

open Nethttp
open Nethttp.Header
open Nethttpd_types
open Nethttpd_kernel
open Nethttpd_services
open Nethttpd_reactor


let get_my_addr () =
  (Unix.gethostbyname(Unix.gethostname())).Unix.h_addr_list.(0) ;;

   
let make_srv req_processor port =
  host_distributor
    [ default_host ~pref_name:"localhost" ~pref_port:port (),
      uri_distributor
        [ "*", (options_service());
          "/", (dynamic_service
                         { dyn_handler = req_processor;
                           dyn_activation = std_activation `Std_activation_buffered;
                           dyn_uri = Some "/service";
                           dyn_translator = (fun _ -> "");
                           dyn_accept_all_conditionals = false
                           })
        ]
    ]




let start_srv req_processor port =
  let config = Nethttpd_reactor.default_http_reactor_config in
  let master_sock = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  Unix.setsockopt master_sock Unix.SO_REUSEADDR true;
  Unix.bind master_sock (Unix.ADDR_INET(Unix.inet_addr_any, port));
  Unix.listen master_sock 100;
  Printf.printf "Listening on port %i\n" port;
  flush stdout;

    while true do
    try
      let conn_sock, _ = Unix.accept master_sock in
      Unix.set_nonblock conn_sock;
      process_connection config conn_sock (make_srv req_processor port);
    with
        Unix.Unix_error(Unix.EINTR,_,_) -> ()  (* ignore *)
  done
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
