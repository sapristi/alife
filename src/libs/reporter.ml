open Batteries
open BatFile
type logger = string -> unit
    
type reporter = {
    loggers : logger list;
    prefix : unit -> string;
    suffix : unit -> string;
  }

let empty_reporter = {
    loggers = [];
    prefix = (fun () -> "");
    suffix = (fun () -> "");
  }
              
let cli_logger s  =
  print_string s

let make_file_logger filename : logger =
  let p = perm [user_read; user_write; group_read; group_write] in
  let oc = open_out ~mode:[`create ; `append] ~perm:p filename in
  (fun s -> Printf.fprintf oc "%s\n" s)


let report reporter log =
  List.iter (fun logger -> logger (Printf.sprintf "%s%s%s" (reporter.prefix ()) log (reporter.suffix ()))) reporter.loggers

