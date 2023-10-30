open Reactors
open Base_chemistry
open Easy_logging_yojson

let log_levels =
  [ Logging.Debug; Info; Warning; NoLevel ]
  |> List.map (function v -> (Logging.show_level v, v))

let set_log_level log_level =
  let root_logger = Logging.get_logger "Yaac"
  and h = Handlers.make (Cli log_level) in
  root_logger#add_handler h;
  root_logger#set_level log_level

let log_level_t =
  Cmdliner.Arg.(
    value & opt (enum log_levels) Logging.Warning & info [ "l"; "log-level" ])

type eval_params = {
  log_level : Logging.level; [@term log_level_t]
  n_steps : int;
  initial_state : string;
}
[@@deriving subliner]

let eval { initial_state; n_steps } =
  let sandbox =
    initial_state |> Yojson.Safe.from_string |> Sandbox.signature_of_yojson
    |> Result.get_ok |> Sandbox.of_signature
  in
  for i = 0 to n_steps - 1 do
    Bacterie_libs.Bacterie.next_reaction !sandbox
  done

let get_pnet mol =
  let res = mol |> Molecule.to_proteine |> Proteine.to_yojson in
  print_endline (Yojson.Safe.to_string res)

let build_all_from_mol mol =
  let prot_json = mol |> Molecule.to_proteine |> Proteine.to_yojson in
  let pnet_json =
    match Petri_net.make_from_mol mol with
    | Some pnet -> Petri_net.to_yojson pnet
    | None -> `Null
  in
  `Assoc [ ("prot", prot_json); ("pnet", pnet_json) ]
  |> Yojson.Safe.to_string |> Result.ok

let build_all_from_prot (prot_str : string) =
  match prot_str |> Yojson.Safe.from_string |> Proteine.of_yojson with
  | Ok prot ->
      let mol = Molecule.of_proteine prot in
      let mol_json = `String mol in
      let pnet_json =
        match Petri_net.make_from_mol mol with
        | Some pnet -> Petri_net.to_yojson pnet
        | None -> `Null
      in
      `Assoc [ ("mol", mol_json); ("pnet", pnet_json) ]
      |> Yojson.Safe.to_string |> Result.ok
  | Error s -> Error s

type params =
  (* Create pnet from mol *)
  | From_mol of { log_level : Logging.level; [@term log_level_t] mol : string }
  (* Create pnet from prot *)
  | From_prot of {
      log_level : Logging.level; [@term log_level_t]
      prot : string;
    }
  (* perform evaluation for given number of steps *)
  | Eval of eval_params
  (* return available reactions *)
  | Reactions
  (* compute a single given reaction *)
  | React
[@@deriving subliner]

let handle = function
  | From_mol { mol; log_level } ->
      set_log_level log_level;
      build_all_from_mol mol
  | From_prot { prot; log_level } ->
      set_log_level log_level;
      build_all_from_prot prot
  | Eval params ->
      eval params |> ignore;
      Ok "todo"
  | Reactions -> Ok "todo"
  | React -> Ok "todo"

let handle_wrapped input =
  match handle input with
  | Ok result -> print_endline result
  | Error err ->
      prerr_endline err;
      exit 1

[%%subliner.cmds eval.params <- handle_wrapped]
(** Some docs *)
