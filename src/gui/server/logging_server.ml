
open Easy_logging_yojson
open Opium.Std

(* let get_loggers =
 *   `Json (Logging.loggers_to_yojson) *)

(* let set_level (req : Opium_kernel__Rock.Request.t) = 
 *   let logger_name = param req "logger"
 *   and level_str = param req "level" in
 *   let logger = Logging.get_logger logger_name in
 *   match Logging.level_of_string level_str with
 *   | Ok level -> 
 *     logger#set_level level;
 *     `Empty
 *   | Error e ->
 *     `Error e *)
