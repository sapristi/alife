(*
    This file is part of easy_logging.

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.
*)


open CalendarLib
type level =
  | Debug
  | Info
  | Warning
  | Error
  | NoLevel

let show_level lvl = match lvl with
  | Debug    -> "Debug"
  | Info     -> "Info"
  | Warning  -> "Warning"
  | Error    -> "Error"
  | NoLevel  -> "NoLevel"

type log_item = {
  level : level;
  logger_name : string;
  msg : string;
  data : (string * Yojson.Safe.t) list;
  timestamp: float;
}


module Handler = struct
  type log_formatter = log_item -> string
  type filter= log_item -> bool

  type t =
    {
      mutable fmt : log_formatter;
      mutable level : level;
      output : string -> unit;
    }

  let json_formatter item =
      Printf.sprintf
        "{\"ts\": %f, \"level\": \"%s\", \"logger_name\": \"%s\", \"message\": \"%s\", \"data\": %s}"
        (item.timestamp)
        (show_level item.level)
        (String.escaped item.logger_name)
        (String.escaped item.msg)
        (Yojson.Safe.to_string (`Assoc item.data))

  let default_handler = {
    fmt = json_formatter;
    level=Info;
    output=(fun s -> output_string stdout s; flush stdout);
  }


  let apply (h : t) (item: log_item) =
    if item.level >= h.level
    then
      (
        h.output (Printf.sprintf "%s\n" (h.fmt item));
      )

end

let debug = ref false

class logger
    ?parent:(parent=None)
    (name: string)
  =
  object(self)

    val name = name

    val mutable level : level = NoLevel

    val mutable handlers : Handler.t list = []

    val parent : logger option = parent

    val mutable propagate = true

    val mutable data_generators : (unit -> (string*Yojson.Safe.t)) list = []

    method name = name
    method set_level new_level = level <- new_level
    method add_handler h = handlers <- h::handlers

    method get_handlers = handlers
    method set_handlers hs = handlers <- hs

    method set_propagate p = propagate <- p

    method effective_level : level =
      match level, parent  with
      | NoLevel, None  -> NoLevel
      | NoLevel, Some p -> p#effective_level
      | l,_ -> l

    method internal_level = level

    method get_handlers_propagate =
      if !debug
      then
        print_endline (Printf.sprintf "[%s] returning (%i) handlers" name
                         (List.length handlers));
      match propagate, parent with
      | true, Some p -> handlers @ p#get_handlers_propagate
      | _ -> handlers

    method add_data_generator t  =
      data_generators <- t :: data_generators

    method private _log_msg : level -> string -> (string*Yojson.Safe.t) list -> unit
      = fun msg_level msg data ->

        if !debug
        then
          print_endline ( Printf.sprintf "[%s]/%s -- Treating msg \"%s\" at level %s"
                            name (show_level level)
                            msg (show_level msg_level));

        let generated_data = List.map (fun x -> x ()) data_generators in
        let item : log_item= {
          level = msg_level;
          logger_name = name;
          msg = msg;
          data=generated_data @ data;
          timestamp = Fcalendar.to_unixfloat @@ Fcalendar.now ()
        } in
        List.iter (fun handler ->
            Handler.apply handler item)
          self#get_handlers_propagate

    method error = self#_log_msg Error
    method warning = self#_log_msg Warning
    method info =  self#_log_msg Info
    method debug = self#_log_msg Debug
  end


let root_logger = new logger "root"

module Infra =
  Easy_logging.Logging_internals.Logging_infra.MakeTree(
  struct
    type t = logger
    let make (n:string) parent = new logger ~parent n
    let root = root_logger
  end)


let get_logger name =
  Infra.get name

let make_logger ?(propagate=true) ?(add_handler=false) name lvl  =
  let l = Infra.get name in
  l#set_level lvl;
  l#set_propagate propagate;
  if add_handler then l#add_handler Handler.default_handler;
  l


let main () =
  let logger = make_logger "MyTest.AB" Info ~add_handler:true in
  logger#info "hello" ["some data", `List [`String "hello"]];
  logger#info "hello" ["some data", `List [`String "hello"]];
  print_endline "hehllo";
  ()

