open Local_libs
   
type config = {
    bact_log_level : Logger.level option;
    reacs_log_level : Logger.level option;
    stats_log_level : Logger.level option;
    internal_log_level : Logger.level option;
  } [@@deriving show]
            
let logconfig = {
    bact_log_level = Some Logger.Info;
    reacs_log_level = Some Logger.Info;
    stats_log_level = None;
    internal_log_level = Some Logger.Info;
  }
