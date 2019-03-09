open Batteries
open BatFile

module Color=
  struct
    type t =
      | Default | Black | Red | Green | Yellow
      | Blue | Magenta | Cyan | White

    let to_fg c =
     match c with 
     | Default -> "\027[39m" | Black -> "\027[30m"  | Red -> "\027[31m"
     | Green -> "\027[32m"   | Yellow -> "\027[33m" | Blue -> "\027[34m"
     | Magenta -> "\027[35m" | Cyan -> "\027[36m"   | White -> "\027[97m"
    let to_bg c = 
     match c with 
     | Default -> "\027[49m" | Black -> "\027[40m"  | Red -> "\027[41m"
     | Green -> "\027[42m"   | Yellow -> "\027[43m" | Blue -> "\027[44m"
     | Magenta -> "\027[45m" | Cyan -> "\027[46m"   | White -> "\027[107m"

    let colorize ?fgc:(fg=Default) ?bgc:(bg=Default) t =
      Printf.sprintf "%s%s%s%s%s" (to_fg fg) (to_bg bg) t (to_fg Default) (to_bg Default)  
  end
   
type level =
  | Flash
  | Error
  | Warning
  | Info
  | Debug

let show_level lvl =
  match lvl with
  | Flash -> "Flash" | Error -> "Error" | Warning -> "Warning"
  | Info -> "Info" | Debug -> "Debug"

let level_gt l1 l2 = match l1,l2 with
  | Flash, _ -> true
  | Error, _ -> true
  | Warning, Error -> false
  | Warning, _ -> false
  | Info, Error | Info, Warning -> false
  | Info, _ -> true
  | Debug, Debug -> true
  | Debug, _ -> false


type log_item = {
    level : level;
    logger_name : string;
    msg : string;
  }

module Formatter =
  struct
    type t = log_item -> string
    let format_default item =
      Printf.sprintf "%-6.3f %-10s %-10s %s" (Sys.time ()) item.logger_name
        (show_level item.level) item.msg

    let level_to_color lvl =
      match lvl with
      | Flash -> Color.Magenta
      | Error -> Color.Red
      | Warning -> Color.Yellow
      | Info -> Color.Blue
      | Debug -> Color.Green
      
    let format_color item =
      let item_level_str = Color.colorize  ~fgc:(level_to_color item.level)  (show_level item.level) in
        
      Printf.sprintf "%-6.3f %-10s %-30s %s" (Sys.time ()) item.logger_name
        item_level_str item.msg
end

  
module Handler =
  struct
    type t =
      {fmt : Formatter.t;
       level : level;
       handler : string -> unit}
      
    let handle (h : t) (item: log_item) =
      if level_gt item.level h.level
      then
        h.handler (h.fmt item)
      
    let make_cli_handler level =
      {fmt = Formatter.format_color;
       level = level;
       handler = fun s -> print_endline s}
      
  (* not very efficient since we open and close the file each time a log is written,
     but this will do for now *)
    let make_file_handler level filename  =
      (* print_endline (Unix.getcwd ());*)
      if not (Sys.file_exists "logs")
      then 
        Unix.mkdir "logs" 0o777;
      {fmt = Formatter.format_default;
       level = level;
       handler =
         fun s ->

         let p = perm [user_read; user_write; group_read; group_write] in
         let oc = open_out ~mode:[`create ; `append] ~perm:p ("logs/"^filename) in
         
         Printf.fprintf oc "%s\n" s;
         close_out oc;
      }
      

    let handlers : (string, t) Hashtbl.t = Hashtbl.create 10
    let register_handler name handler =
      Hashtbl.replace handlers name handler

      
    type desc = | Cli of level | File of string * level | Reg of string
    let make d = match d with
      | Cli lvl -> make_cli_handler lvl
      | File (f, lvl) -> make_file_handler lvl f
      | Reg n ->
         Hashtbl.find handlers n
           
  end
  
  
class logger
        (name: string)
        (levelo: level option)
        (handlers_desc : Handler.desc list)  =
  
  object(self)
    val mutable handlers  = List.map Handler.make handlers_desc
    val mutable levelo : level option = levelo

    method log_msg (msg_level : level) msg =
      match levelo with
      | None ->()
      | Some level ->
         if level_gt msg_level level
         then
           begin
           let item = {
               level = msg_level;
               logger_name = name;
               msg = msg} in 
           List.iter (fun handler ->
               Handler.handle handler item)
             handlers
           end
         else
           ()                           
                       
    method add_handler h = handlers <- h::handlers
    method set_level new_levelo = levelo <- new_levelo
                         
    method flash = self#log_msg Flash
    method error = self#log_msg Error
    method warning = self#log_msg Warning
    method info =  self#log_msg Info
    method debug = self#log_msg Debug

end

let dummy = new logger "dummy" None []

