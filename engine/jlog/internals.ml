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

  module Name = struct
    type s = string
    type l = string list
    let to_l (s: s) : l = if s = "" then [] else String.split_on_char '.' s
    let to_s: l -> s = join "."
  end

end

module Types = struct
  type level = | Debug | Info | Warning | Error | NoLevel
  type tags = (string * Yojson.Safe.t) list
  let string_of_level level = match level with | Debug -> "Debug" | Info -> "Info" | Warning -> "Warning" | Error -> "Error" | NoLevel -> "NoLevel"


  type log_item = {
    timestamp : float;
    level: level;
    logger: string;
    message: string;
    tags: tags;
  }

  let log_item_to_yojson log_item: Yojson.Safe.t = 
    `Assoc [
      "timestamp", `Float log_item.timestamp;
      "logger", `String log_item.logger;
      "message", `String log_item.message;
      "level", `String (log_item.level |> string_of_level);
      "tags", `Assoc log_item.tags
    ]
  type handler = {
    formatter: log_item -> string;
    output: string -> unit;
    level: level;
    propagate: bool;
  }
  type log_infra = {
    mutable handlers: ((string list) * handler) list
  }

  type log_function = ?tags:tags -> ?ltags:(tags Lazy.t) -> string -> unit
  type logger = {
    debug: log_function;
    info: log_function;
    warning: log_function;
    error: log_function;
  }
end

open Types

type name_l = string list


exception Break

let handle (log_item: log_item) (handler: handler) =
  if log_item.level < handler.level
  then raise Break;
  log_item |> handler.formatter |> handler.output;
  if not handler.propagate then raise Break


let find_handlers log_infra (name_l: name_l) level=
  if (!_debug) then
    Printf.printf "Searching handlers for %s at %s\n" (name_l |> Utils.Name.to_s) (level |> string_of_level);
  log_infra.handlers |> List.filter (fun (hname, handler) -> Utils.is_list_prefix hname name_l)
  |> List.sort Utils.compare_list_lengths
  |> List.map (fun (_, handler) -> handler)


let _log log_infra (name_l: name_l) (name: string) (level: level) ?(tags=[]) ?(ltags=lazy []) (message: string) =
  let timestamp = (Unix.gettimeofday ()) in
  let log_handlers = find_handlers log_infra name_l level in
  let log_item = {
    logger=name;
    message=message;
    tags=tags@(Lazy.force ltags);
    level=level;
    timestamp;
  } in
  if (!_debug) then
    Printf.printf "Logging %s with %d handlers\n" name (List.length log_handlers);
  try
    List.iter (handle log_item) log_handlers
  with | Break -> ()






