open Batteries
open BatFile

module Color=
  struct
    type color =
      | Default | Black | Red | Green | Yellow
      | Blue | Magenta | Cyan | Gray | White 
      | LRed | LGreen | LYellow | LBlue
      | LMagenta | LCyan | LGray

    type style =
      | Bold | Underline | Invert | NoStyle

    let style_to_string s =
      match s with
      | Bold -> "\027[1m"   | Underline -> "\027[4m" | Invert -> "\027[7m"  
      | NoStyle -> "\027[0m"
                                                               
    let to_fg c =
     match c with 
     | Default -> "\027[39m" | Black -> "\027[30m"  | Red -> "\027[31m"
     | Green -> "\027[32m"   | Yellow -> "\027[33m" | Blue -> "\027[34m"
     | Magenta -> "\027[35m" | Cyan -> "\027[36m"   | Gray -> "\027[90m"
     | White -> "\027[97m"   | LRed -> "\027[91m"   | LGreen -> "\027[92m"
     | LYellow -> "\027[93m" | LBlue -> "\027[94m"  | LMagenta -> "\027[95m"
     | LCyan -> "\027[96m"   | LGray -> "\027[37m"

    let to_bg c = 
     match c with 
     | Default -> "\027[49m" | Black -> "\027[40m"  | Red -> "\027[41m"
     | Green -> "\027[42m"   | Yellow -> "\027[43m" | Blue -> "\027[44m"
     | Magenta -> "\027[45m" | Cyan -> "\027[46m"   | Gray -> "\027[100m"
     | White -> "\027[107m"  | LRed -> "\027[101m"  | LGreen -> "\027[102m"
     | LYellow -> "\027[103m"| LBlue -> "\027[104m"  | LMagenta -> "\027[105m"
     | LCyan -> "\027[106m"   | LGray -> "\027[47m"

    let colorize ?fgc:(fg=Default) ?bgc:(bg=Default) ?s:(style=NoStyle) t =
      Printf.sprintf "%s%s%s%s%s%s%s" (style_to_string style) (to_fg fg) (to_bg bg) t (to_fg Default) (to_bg Default)  (style_to_string NoStyle)
  end
   
type level =
  | Flash
  | Error
  | Warning
  | Info
  | Debug
[@@deriving ord, show { with_path = false }]

type levelo = level option
            [@@deriving show ]
  
let level_gt l1 l2 =
  compare_level l1 l2 <= 0


type log_item = {
    level : level;
    logger_name : string;
    msg : string;
  }

              
type log_formatter = log_item -> string
           
let format_default item =
  Printf.sprintf "%-6.3f %-20s %-10s %s" (Sys.time ()) item.logger_name
    (show_level item.level) item.msg
  
      
let format_color item =
  
  let level_to_color lvl =
    match lvl with
    | Flash -> Color.LMagenta
    | Error -> Color.LRed
    | Warning -> Color.LYellow
    | Info -> Color.LBlue
    | Debug -> Color.Green
  in
  
  let item_level_str = Color.colorize  ~fgc:(level_to_color item.level)  (show_level item.level) in
  let item_msg_str =
    match item.level with
    | Flash -> Color.colorize ~fgc:Color.Black ~bgc:Color.LMagenta item.msg
    | _ -> item.msg in
  
  (Printf.sprintf "%-6.3f %-20s %-30s %s" (Sys.time ()) item.logger_name
     item_level_str item_msg_str)
  
   
module type HandlersT =
  sig
    
    type t =
      {mutable fmt : log_formatter;
       mutable level : level;
       output : unit IO.output}

    val handle : t -> log_item -> unit
    type desc
    val make : desc -> t
  end
  
module DefaultHandlers =
  struct
    type t =
      {mutable fmt : log_formatter;
       mutable level : level;
       output : unit IO.output}


    let outputs : (string, unit IO.output) Hashtbl.t =  Hashtbl.create 10
      
    let handle (h : t) (item: log_item) =
      if level_gt item.level h.level
      then
        (
          IO.write_line h.output (Printf.sprintf "%s" (h.fmt item));
          IO.flush h.output;
        )
              
    let make_cli_handler level =
      Hashtbl.replace outputs "stdout" IO.stdout;
      {fmt = format_color;
       level = level;
       output = IO.stdout}
      
  (* not very efficient since we open and close the file each time a log is written,
     but this will do for now *)
    let make_file_handler level filename  =

      if not (Sys.file_exists "logs")
      then  
        Unix.mkdir "logs" 0o777;

      let oc = 
        if Hashtbl.mem outputs filename
        then
          Hashtbl.find outputs filename
        else
          let p = perm [user_read; user_write; group_read; group_write] in
          open_out ~mode:[`create (*; `append *)] ~perm:p ("logs/"^filename)
      in
      {fmt = format_default;
       level = level;
       output = oc;
      }

    let set_level h lvl =
      h.level <- lvl
    let set_formatter h fmt =
      h.fmt <- fmt

    let handlers : (string, t) Hashtbl.t = Hashtbl.create 10
    let register_handler name handler =
      Hashtbl.replace handlers name handler

      
    type desc = | Cli of level | File of string * level | Reg of string
    let make d = match d with
      | Cli lvl -> make_cli_handler lvl
      | File (f, lvl) -> make_file_handler lvl f
      | Reg n ->
         Hashtbl.find handlers n

    let handle_test h fmt =
      List.iter  (fun x -> handle h fmt )
        [{level=Flash; logger_name="Flash"; msg="Flash"};
         {level=Error; logger_name="Error"; msg="Error"}; 
         {level=Warning; logger_name="Warning"; msg="Warning"};
         {level=Info; logger_name="Info"; msg="Info"};
         {level=Debug; logger_name="Debug"; msg="Debug"}] 
  end
  
module Make (H : HandlersT) =
  struct
    class logger
            (name: string)
            (levelo: level option)
            (handlers_desc : H.desc list)  =
    object(self)
      val mutable handlers = List.map H.make handlers_desc
      val mutable levelo = levelo
      val name = name
               
      method log_msg msg_level msg =
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
                   H.handle handler item)
                 handlers
             end
           else
             ()                           
          
      method log_msg_lazy (msg_level : level) msg =
        match levelo with
        | None ->()
        | Some level ->
           if level_gt msg_level level
           then
             begin
               let item = {
                   level = msg_level;
                   logger_name = name;
                   msg = Lazy.force msg} in 
               List.iter (fun handler ->
                   H.handle handler item)
                 handlers
             end
           else
             ()
      method add_handler h = handlers <- h::handlers
      method set_level new_levelo =
        levelo <- new_levelo
        
      method flash = self#log_msg Flash
      method error = self#log_msg Error
      method warning = self#log_msg Warning
      method info =  self#log_msg Info
      method debug = self#log_msg Debug
                   
      method lflash = self#log_msg_lazy Flash
      method lerror = self#log_msg_lazy Error
      method lwarning = self#log_msg_lazy Warning
      method linfo =  self#log_msg_lazy Info
      method ldebug = self#log_msg_lazy Debug
    end


  
    let _loggers : (string, logger) Hashtbl.t =  Hashtbl.create 10
                                               
    let set_level p lvlo =
      Hashtbl.iter
        (fun n l  ->
          
          if String.starts_with n p
          then
            l#set_level lvlo;)
        _loggers
      
    let get_logger name =
      if Hashtbl.mem _loggers name
      then
        Hashtbl.find _loggers name
      else
        let l = new logger name None [] in
        Hashtbl.add _loggers name l;
        l
        
    let make_logger ?lvl:(lvl=None) ?hdescs:(hdescs=[]) name =
      let l = new logger name lvl hdescs in
      Hashtbl.add _loggers name l;
      l
      
      
    let dummy = make_logger "dummy" ~lvl:None ~hdescs:[]

    type hdesc = H.desc
  end

module Logger = Make(DefaultHandlers)

(* module logger for maybe far later *)
          
  
