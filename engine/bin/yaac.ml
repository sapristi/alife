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

module FromMolCmd = struct
  type params = { log_level : Logging.level; [@term log_level_t] mol : string }
  [@@deriving subliner]

  let doc = "Compute petri net from molecule."

  let build_all_from_mol mol =
    let prot_json = mol |> Molecule.to_proteine |> Proteine.to_yojson in
    let pnet_json =
      match Petri_net.make_from_mol mol with
      | Some pnet -> Petri_net.to_yojson pnet
      | None -> `Null
    in
    `Assoc [ ("prot", prot_json); ("pnet", pnet_json) ]
    |> Yojson.Safe.to_string |> Result.ok

  let handle {log_level; mol} =
    set_log_level log_level;
    build_all_from_mol mol
end

module FromProtCmd = struct
  type params = {
    log_level : Logging.level; [@term log_level_t]
    prot : string;
  }
  [@@deriving subliner]
  let doc = "Compute petri net from proteine."

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

  let handle {log_level; prot} =
    set_log_level log_level;
    build_all_from_prot prot
end

module EvalCmd = struct
  type params = {
    log_level : Logging.level; [@term log_level_t]
    n_steps : int;
    initial_state : string;
  }
  [@@deriving subliner]
  let doc = "Runs the computation, from the given initial state, for the given number of steps.\nTODO"

  let eval initial_state n_steps =
    let bacterie =
      initial_state |> Yojson.Safe.from_string |> Bacterie_libs.Bacterie.BactSig.of_yojson
      |> Result.get_ok |> Bacterie_libs.Bacterie.BactSig.to_bact
    in
    for i = 0 to n_steps - 1 do
      Bacterie_libs.Bacterie.next_reaction bacterie
    done;
    bacterie

  let handle {log_level; initial_state; n_steps} =
    set_log_level log_level;
    let res_bact = eval initial_state n_steps in
      Bacterie_libs.Bacterie.FullSig.bact_to_yojson res_bact
    |> Yojson.Safe.to_string |> Result.ok

end

let get_pnet mol =
  let res = mol |> Molecule.to_proteine |> Proteine.to_yojson in
  print_endline (Yojson.Safe.to_string res)


type params =
  | From_mol of FromMolCmd.params
                [@doc FromMolCmd.doc]
  | From_prot of FromProtCmd.params
      [@doc FromProtCmd.doc]
  | Eval of EvalCmd.params
            [@doc EvalCmd.doc]
  | Reactions
    [@doc "Display available reactions.\nTODO"]
  | React
    [@doc "Computes from the given state, after triggering the given reaction.\nTODO"]
[@@deriving subliner]

let handle = function
  | From_mol params -> FromMolCmd.handle params
  | From_prot params -> FromProtCmd.handle params
  | Eval params -> EvalCmd.handle params
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
