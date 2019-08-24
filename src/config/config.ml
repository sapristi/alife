
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
                "handlers": [ {"cli": {"level":"info"}},  {"file": {"filename": "yaac", "level": "debug"}} ] },
            {
                "name": "Yaac.Bact",
                "level": "info"},
            {
                "name": "Yaac.Bact.Internal",
                "level": "warning"},
            {
                "name": "Yaac.Libs",
                "level": "info"},
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
let check_reac_rates = false
let check_sqrt = true
let check_mol = true

(* *)
let remove_empty_reactants = true

(* Set to true to enable "discover mode":
   it is easier to understand what happens in the molbuilder.
   Pnet with no transitions will be enabled as such.


   Set to false for better performances. *)
let build_inactive_pnets = false
