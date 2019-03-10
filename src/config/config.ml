open Local_libs
   
type config = {
    mutable bact_log_level : Logger.level option;
    mutable reacs_log_level : Logger.level option;
    mutable stats_log_level : Logger.level option;
    mutable internal_log_level : Logger.level option;
  }

let sandbox_config = {
    bact_log_level = Some Debug;
    reacs_log_level = Some Debug;
    stats_log_level = None;
    internal_log_level = Some Debug;
  }


let simulator_config = {
    bact_log_level = Some Warning;
    reacs_log_level = Some Warning;
    stats_log_level = None;
    internal_log_level = None;}

let config = {
    bact_log_level = Some Debug;
    reacs_log_level = Some Debug;
    stats_log_level = None;
    internal_log_level = Some Debug;
  }
