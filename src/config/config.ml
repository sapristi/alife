open Local_libs
   
type config = {
    bact_log_level : Logger.level option ref;
    reacs_log_level : Logger.level option ref;
    stats_log_level : Logger.level option ref;
    internal_log_level : Logger.level option ref;
  } [@@deriving show]
            
let logconfig = {
    bact_log_level = ref (Some Logger.Info);
    reacs_log_level = ref (Some Logger.Info);
    stats_log_level = ref None;
    internal_log_level = ref (Some Logger.Info);
  }
