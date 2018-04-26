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


  (* not very efficient since we open and close the file each time a log is written,
     but this will do for now *)
let make_file_logger filename : logger =
  (fun s ->
    
    let p = perm [user_read; user_write; group_read; group_write] in
    let oc = open_out ~mode:[`create ; `append] ~perm:p filename in
    
    Printf.fprintf oc "%s\n" s;
    close_out oc;
  )
  

let report reporter log =
  List.iter (fun logger -> logger (Printf.sprintf "%s%s%s" (reporter.prefix ()) log (reporter.suffix ()))) reporter.loggers

