open Internals
open Internals.Types


let default (log_item: log_item) =
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


let pp_colored_level formatter level =
  let level_to_color lvl =
    match lvl with
    | Error -> Colorize.LRed
    | Warning -> Colorize.LYellow
    | Info -> Colorize.LBlue
    | Debug -> Colorize.Green
    | NoLevel -> Colorize.Default
  in
  Format.fprintf formatter "%-17s" Colorize.(format [ Fg (level_to_color level)]  (string_of_level level))
and green_formatter = Colorize.(make_formatter [Fg Green])
and bold_formatter = Colorize.(make_formatter [Bold])
let color (log_item: log_item) =
  let tags_str =
    if List.length log_item.tags = 0
    then ""
    else Format.sprintf " - %s" (
        Utils.join " - " (
          List.map (
            fun (name, value) ->
              Format.asprintf "%a: %a" green_formatter name Yojson.Safe.pp value
          ) log_item.tags
        ))
  in
  Format.asprintf "[%.3f] %a - %s - %a%s"
    log_item.timestamp
    pp_colored_level log_item.level
    log_item.logger
    bold_formatter log_item.message
    tags_str

let json (log_item: log_item) =
  log_item  |> log_item_to_yojson |> Yojson.Safe.to_string
