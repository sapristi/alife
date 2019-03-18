
open Easy_logging
   
type config = {
    bact_log_level : log_level option;
    reacs_log_level : log_level option;
    stats_log_level : log_level option;
    internal_log_level : log_level option;
  } [@@deriving show]
            
let logconfig = {
    bact_log_level = Some Info;
    reacs_log_level = Some Info;
    stats_log_level = None;
    internal_log_level = Some Info;
  }

type num_choice =
  | Sloppy | ExactZ | ExactQ

let num = Sloppy
