let _debug = ref false

module Utils = struct
  let join (sep: string) (values: string list) =
    match values with
    | [] -> ""
    | h::[] -> h
    | h::t ->
      List.fold_left (fun res value -> res^sep^value) h t

  let rec is_list_prefix l1 l2 = match l1, l2 with
    | h1::t1, h2::t2 ->
      (
        if (!_debug) then  Format.printf "Compare %s %s \n" h1 h2;
        h1 = h2 && is_list_prefix t1 t2
      )
    | [], _ -> true
    | _, [] -> false

  let compare_list_lengths (l1,_) (l2, _) =
  - (compare (List.length l1) (List.length l2))
end

type level = | Debug | Info | Warning | Error | NoLevel

let string_of_level level = match level with | Debug -> "Debug" | Info -> "Info" | Warning -> "Warning" | Error -> "Error" | NoLevel -> "NoLevel"

module Core =
struct

  type tags = (string * Yojson.Safe.t) list
  module Name = struct
      type t = string
      type l = string list
      let to_l (s: t) : l = if s = "" then [] else String.split_on_char '.' s
      let to_t: l -> t = Utils.join "."
    end
  type name = string
  type name_l = string list
  type log_item = {
    timestamp : float;
    level: level;
    logger: name;
    message: string;
    tags: tags;
  }

  type handler = {
    formatter: log_item -> string;
    output: string -> unit;
    level: level;
    propagate: bool;
  }
  type log_infra = {
    mutable handlers: ((string list) * handler) list
  }

  let log_item_to_yojson log_item: Yojson.Safe.t = 
    `Assoc [
      "timestamp", `Float log_item.timestamp;
      "logger", `String log_item.logger;
      "message", `String log_item.message;
      "level", `String (log_item.level |> string_of_level);
      "tags", `Assoc log_item.tags
    ]

  exception Break
  let handle (log_item: log_item) (handler: handler) =
    if log_item.level < handler.level
    then raise Break;
    log_item |> handler.formatter |> handler.output;
    if not handler.propagate then raise Break

  (** TODO: stop when not propagating *)
  let find_handlers log_infra (name_l: name_l) level=
    if (!_debug) then
      Printf.printf "Searching handlers for %s at %s\n" (name_l |> Name.to_t) (level |> string_of_level);
    log_infra.handlers |> List.filter (fun (hname, handler) -> Utils.is_list_prefix hname name_l)
    |> List.sort Utils.compare_list_lengths
    |> List.map (fun (_, handler) -> handler)


  let _log log_infra (name_l: name_l) (name: string) (level: level) ?(tags=[]) ?(ltags=fun ()-> []) (message: string) =
    let timestamp = (Unix.gettimeofday ()) in
    let log_handlers = find_handlers log_infra name_l level in
    let log_item = {
      logger=name;
      message=message;
      tags=tags@(ltags ());
      level=level;
      timestamp;
    } in
    if (!_debug) then
      Printf.printf "Logging %s with %d handlers\n" name (List.length log_handlers);
    try
      List.iter (handle log_item) log_handlers
    with | Break -> ()

end

open Core

let log_infra = {
  handlers = []
}

let register_handler name handler =
  let name_l = Name.to_l name in
  log_infra.handlers <- (name_l, handler)::log_infra.handlers


type log_function = ?tags:tags -> ?ltags:(unit -> tags) -> string -> unit
type logger = {
  debug: log_function;
  info: log_function;
  warning: log_function;
  error: log_function;
}

let make_logger name =
  let name_l = Name.to_l name in
  let _log_custom = _log log_infra name_l name
  in {
        debug=_log_custom Debug;
        info=_log_custom  Info;
        warning=_log_custom Warning;
        error=_log_custom Error;
      }


let default_formatter (log_item: log_item) =
  let tags_str =
    if List.length log_item.tags = 0
    then ""
    else Format.sprintf " - %s" (
        Utils.join " - " (
          List.map (
            fun (name, value) ->
              Format.sprintf "%s: %s" name (value |> Yojson.Safe.to_string)
          ) log_item.tags
        )) in
  Format.sprintf "[%.3f] %-7s - %s - %s%s" log_item.timestamp (log_item.level |> string_of_level) log_item.logger log_item.message tags_str

let json_formatter (log_item: log_item) =
  log_item  |> log_item_to_yojson |> Yojson.Safe.to_string

let make_handler ?(formatter=default_formatter) ?(output=print_endline) ?(level=Debug) ?(propagate=false) () =
  {
    formatter; output; level; propagate
  }


