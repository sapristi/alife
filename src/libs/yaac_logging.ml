open Easy_logging_yojson

module YaacTags =
  struct
    type tag =
      | RMgr of (int * (string * string * string))

    let rec tags_formatter (tags: tag list) =
      match tags with
      | [] -> ""
      | h :: t ->
         match h with
         | RMgr (rnum, (trate, grate, brate)) ->
            
            Printf.sprintf "[%i,(G: %s, T: %s, B: %s)] "
              rnum trate grate brate
            ^ (tags_formatter t)
  end
  
       
module YaacHandlers = MakeDefaultHandlers(YaacTags)
type log_level = Easy_logging_yojson.log_level
               [@@deriving show]
module Logging = MakeLogging(YaacHandlers)
let log_level_of_string = Easy_logging_yojson.log_level_of_string
