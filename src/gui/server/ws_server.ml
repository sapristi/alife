open Lwt.Infix
open Websocket
open Websocket_lwt_unix

open Easy_logging_yojson

let logger = Logging.get_logger "Yaac.Server.WS"


let handler id pipe client=
  incr id;

  print_endline "I AM CONNECTED";

  let id = !id in
  let send = Connected_client.send client in
  logger#info "New connection (id = %d)" id;
  (* Lwt.async (fun () ->
   *     Lwt_unix.sleep 1.0 >|= fun () ->
   *     send @@ Frame.create ~content:"Delayed message" ()
   *   ); *)
  (* let rec recv_forever () =
   *   let open Frame in
   *   let react fr =
   *     logger#debug "<- %s" (Frame.show fr)|> Lwt.return >>= fun () ->
   *     match fr.opcode with
   *     | Opcode.Ping ->
   *       send @@ Frame.create ~opcode:Opcode.Pong ~content:fr.content ()
   * 
   *     | Opcode.Close ->
   *       logger#info "Client %d sent a close frame" id |> Lwt.return >>= fun () ->
   *       (\* Immediately echo and pass this last message to the user *\)
   *       (if String.length fr.content >= 2 then
   *          send @@ Frame.create ~opcode:Opcode.Close
   *            ~content:(String.sub fr.content 0 2) ()
   *        else send @@ Frame.close 1000) >>= fun () ->
   *       Lwt.fail Exit
   * 
   *     | Opcode.Pong -> Lwt.return_unit
   * 
   *     | Opcode.Text
   *     | Opcode.Binary -> send @@ Frame.create ~content:"OK" ()
   * 
   *     | _ ->
   *       send @@ Frame.close 1002 >>= fun () ->
   *       Lwt.fail Exit
   *   in
   *   Connected_client.recv client >>= react >>= recv_forever; *)

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
  print_endline (Printexc.get_backtrace ());
  print_endline  (Printexc.to_string e);;

let tcp_mode = `TCP (`Port 5000);;

let run pipe () =
  logger#info "Running websocket server";
  Websocket_lwt_unix.establish_standard_server ~mode:tcp_mode ~on_exn:catch_exn ~check_request  (handler (ref (-1)) pipe)

