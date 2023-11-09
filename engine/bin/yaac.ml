open Base_chemistry
open Bacterie_libs
open Local_libs

let logger = Alog.make_logger "Yaac.Cmd"

let log_levels =
  [ Alog.Debug; Info; Warning; NoLevel ]
  |> List.map (function v -> (Alog.string_of_level v, v))

let set_log_level log_level =
  let root_handler =  Alog.make_handler ~formatter:Alog.default_formatter ~level:log_level () in
  Alog.register_handler "Yaac" root_handler

let log_level_t =
  Cmdliner.Arg.(
    value & opt (enum log_levels) Alog.Warning & info [ "l"; "log-level" ])

module FromMolCmd = struct
  type params = { log_level : Alog.level; [@term log_level_t] mol : string }
  [@@deriving subliner]

  let doc = "Compute petri net from molecule."

  let build_all_from_mol mol =
    let prot_json = mol |> Molecule.to_proteine |> Proteine.to_yojson in
    let pnet_json =
      match Petri_net.make_from_mol 0 mol with
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
    log_level : Alog.level; [@term log_level_t]
    prot : string; [@doc "JSON representation of the proteine"]
  }
  [@@deriving subliner]
  let doc = "Compute petri net from proteine."

  let build_all_from_prot (prot_str : string) =
    match prot_str |> Yojson.Safe.from_string |> Proteine.of_yojson with
    | Ok prot ->
      let mol = Molecule.of_proteine prot in
      let mol_json = `String mol in
      let pnet_json =
        match Petri_net.make_from_mol 0 mol with
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
    log_level : Alog.level; [@term log_level_t]
    nb_steps : int;
    initial_state : string; [@doc "JSON representation of the initial state"]
    use_dump : bool; [@doc "The initial state is a full-dump"] [@default false]
  }
  [@@deriving subliner]
  let doc = "Runs the computation, from the given initial state, for the given number of steps."

  let handle {log_level; initial_state; nb_steps; use_dump} =
    set_log_level log_level;
    let bact =
      if use_dump
      then
        initial_state |> Yojson.Safe.from_string |> Bacterie_libs.Bacterie.FullSig.bact_of_yojson
        |> Result.get_ok
      else
        initial_state |> Yojson.Safe.from_string |> Bacterie_libs.Bacterie.CompactSig.of_yojson
        |> Result.get_ok |> Bacterie_libs.Bacterie.CompactSig.to_bact
    in
    for i = 0 to nb_steps - 1 do
      try
        Bacterie_libs.Bacterie.next_reaction bact
      with  exc -> (
          logger.error ~tags:[
            "Bact", Bacterie.FullSig.bact_to_yojson bact;
            "Reactions", Reac_mgr.to_yojson bact.reac_mgr
          ] "Reaction failed";
          raise exc
        )
    done;

    Bacterie.FullSig.bact_to_yojson bact
    |> Yojson.Safe.to_string |> Result.ok

end

module ReactionsCmd = struct
  let doc = "Display available reactions from the given state."
  type params = {
    log_level : Alog.level; [@term log_level_t]
    state : string; [@doc "JSON representation of the initial state"]
  }
  [@@deriving subliner]

  let handle {log_level; state} =
    set_log_level log_level;
    let bact = state |> Yojson.Safe.from_string |> Bacterie_libs.Bacterie.FullSig.bact_of_yojson
               |> Result.get_ok
    in
    bact.reac_mgr |> Reac_mgr.to_yojson|> Yojson.Safe.to_string |> Result.ok
end

type params =
  | From_mol of FromMolCmd.params
                [@doc FromMolCmd.doc]
  | From_prot of FromProtCmd.params
                 [@doc FromProtCmd.doc]
  | Eval of EvalCmd.params
            [@doc EvalCmd.doc]
  | Reactions of ReactionsCmd.params
    [@doc ReactionsCmd.doc]
  | React
    [@doc "Computes from the given state, after triggering the given reaction.\nTODO"]
[@@deriving subliner]

let handle = function
  | From_mol params -> FromMolCmd.handle params
  | From_prot params -> FromProtCmd.handle params
  | Eval params -> EvalCmd.handle params
  | Reactions params -> ReactionsCmd.handle params
  | React -> Ok "ok"

let handle_wrapped input =
  match handle input with
  | Ok result -> print_endline result
  | Error err ->
      prerr_endline err;
      exit 1

[%%subliner.cmds eval.params <- handle_wrapped]
