open Easy_logging_yojson
open Opium.Std
open Lwt.Infix

let logger = Logging.get_logger "Yaac.Server.Logs"

let get_loggers req =
  `Json (Logging.tree_to_yojson ()) |> Lwt.return

let set_level (req : Opium_kernel__Rock.Request.t) =
  let%lwt data_json =
    req.body
    |> Cohttp_lwt.Body.to_string
    >|= Yojson.Safe.from_string
  in

  let level_json = Yojson.Safe.Util.member "level" data_json in
  let logger_name_json = Yojson.Safe.Util.member "logger" data_json in
  match level_json, logger_name_json with
  | `String level_str, `String logger_name ->
    logger#debug "setting %s to %s" logger_name level_str;
    let temp_logger = Logging.get_logger logger_name in
    (
      match Logging.level_of_string level_str with
      | Ok level ->
        temp_logger#set_level level;
        `Empty
      | Error e ->
        `Error e
    ) |> Lwt.return
  | _ -> `Error "Invalid input data" |> Lwt.return

let make_routes () =
  [ get  "/api/logs/tree", get_loggers;
    post "/api/logs/logger", set_level]
