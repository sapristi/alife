
let default_log_config_str = {|
{
    "handlers": {
        "file_handlers": {
             "logs_folder" : "logs",
             "truncate" : false
        }
    },
    "loggers": 
        [
            {
                "name": "Yaac",
                "level": "debug",
                "handlers": [ {"cli": {"level":"debug"}} ] },
            {
                "name": "Yaac.Bact",
                "level": "info"},
            {
                "name": "Yaac.Bact.Internal",
                "level": "warning"},
            
            {
                "name": "Yaac.Server",
                "level" : "info"},
            {
                "name": "Yaac.stats",
                "level": "nolevel",
                "propagate" : false }
        ]
} |}

type num_choice =
  | Sloppy | ExactZ | ExactQ

let num = ExactQ
let check_reac_rates = true
let keep_empty_reactants = true
