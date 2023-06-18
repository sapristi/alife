(* * simulation server *)

(* ** preamble*)
open Sim_req_handler
open Sandbox_req_handler
open Bacterie_libs
open Reactors
open Local_libs
open Easy_logging_yojson
open Base_chemistry
open Chemistry_types
let logger = Logging.get_logger "Yaac.Server.Bact"


open Lwt.Infix


let set_log_level (cgi) : string =
  let loggername = cgi#argument_value "logger" in
  match cgi#argument_value "level"
        |> Logging_internals.Logging_types.level_of_string with
  | Ok level ->
    let logger = Logging.get_logger loggername in
    logger#set_level level;
    "\"ok\""
  | Error r ->
    r

let build_all_from_mol (req : Opium.Request.t)=
  match%lwt
    req
    |> Opium.Request.to_json_exn
    >|= Molecule.of_yojson
  with
  | Ok mol ->
    let prot_json = mol
                    |> Molecule.to_proteine
                    |> Proteine.to_yojson
    in
    let pnet_json =
      match Petri_net.make_from_mol mol with
      | Some pnet -> Petri_net.to_yojson pnet
      | None -> `Null
    in
    `Json (
      `Assoc
        [ "prot", prot_json;
          "pnet", pnet_json]
    ) |> Lwt.return
  | Error s -> `Error s |> Lwt.return


let build_all_from_prot (req : Opium.Request.t) =
  let%lwt body =
    req
    |> Opium.Request.to_plain_text
  in

  logger#debug "Received %s" body;
  match
    body
    |> Yojson.Safe.from_string
    |> Proteine.of_yojson
  with
  | Ok prot ->
    (
      let mol = Molecule.of_proteine prot in
      let mol_json = `String mol in
      let pnet_json =
        match Petri_net.make_from_mol mol with
        | Some pnet -> Petri_net.to_yojson pnet
        | None -> `Null
      in
      `Json (`Assoc
               ["mol", mol_json;
                "pnet", pnet_json])
      |> Lwt.return
    )
  | Error s -> `Error s |> Lwt.return



open Lwt.Infix
type build_req_body =
  | Mol of Molecule.t
  | Prot of Proteine.t
[@@deriving yojson]



let acids_list  =
  let json_data =
    `Assoc
      ["purpose", `String "list_acids";
       "data", `List [
         `Assoc ["type", `String "places";
                 "acids", `List (List.map Types.Acid.acid_to_yojson Types.Acid.Examples.nodes)];
         `Assoc ["type", `String "inputs_arcs";
                 "acids", `List (List.map Types.Acid.acid_to_yojson Types.Acid.Examples.input_arcs)];
         `Assoc ["type", `String "outputs_arcs";
                 "acids", `List (List.map Types.Acid.acid_to_yojson Types.Acid.Examples.output_arcs)];
         `Assoc ["type", `String "extensions";
                 "acids", `List (List.map Types.Acid.acid_to_yojson Types.Acid.Examples.extensions);]]] in
  `Json json_data |> Lwt.return


let make_routes simulator sandbox db_uri =
  [ Opium.App.get, "/api/utils/acids", (fun x -> acids_list );
    Opium.App.post, "/api/utils/build/from_mol", build_all_from_mol;
    Opium.App.post, "/api/utils/build/from_prot", build_all_from_prot ]
  @ (Utils.add_prefix "/api/sandbox" (Sandbox_req_handler.make_routes sandbox db_uri))
  @ (Logs_server.make_routes ())
