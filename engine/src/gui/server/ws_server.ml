open Lwt.Infix
open Websocket
open Websocket_lwt_unix

open Easy_logging_yojson

let logger = Logging.get_logger "Yaac.Server.WS"

let port = 5000

let handler id pipe client=
  incr id;

  let id = !id in
  let send = Connected_client.send client in
  logger#info "New connection (id = %d)" id;

  let rec send_logs pipe ()=
    (
      match%lwt Lwt_pipe.read pipe with
      | Some msg -> send @@ Frame.create ~content:msg ()
      | None -> Lwt.return ()
    ) >>=
    fun () -> send_logs pipe ()

  in
  Lwt.catch
    (send_logs pipe)
    (fun exn ->
       Lwt.return (logger#info  "Connection to client %d lost" id)  >>= fun () ->
       Lwt.fail exn)


let check_request x = true;;

let catch_exn exn = match exn with | _ as e ->
  logger#serror (Printexc.get_backtrace ());
  logger#serror  (Printexc.to_string e);;

let tcp_mode = `TCP (`Port port);;

let run pipe () =
  logger#info "Running websocket server on port %i" port;
  Websocket_lwt_unix.establish_standard_server ~mode:tcp_mode ~on_exn:catch_exn ~check_request  (handler (ref (-1)) pipe)
