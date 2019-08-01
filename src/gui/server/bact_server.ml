(* * simulation server *)

(* ** preamble*)
open Sim_req_handler
open Sandbox_req_handler
open Bacterie_libs
open Reactors
open Local_libs   
open Easy_logging_yojson
let logger = Logging.get_logger "Server.Bact"


type req_result =
  | Res_Yojson of Yojson.Safe.t
  | Res_String of string
  | Res_Error of string

let set_log_level (cgi: Netcgi.cgi) : string =
  let loggername = cgi#argument_value "logger" in
  match cgi#argument_value "level"
        |> Logging.level_of_string with
  | Ok level ->  
     let logger = Logging.get_logger loggername in
     logger#set_level level;
     "ok"
  | Error r -> 
     r
  
let build_all_from_mol mol : Yojson.Safe.t=
  let prot_json = mol
                  |> Molecule.to_proteine
                  |> Proteine.to_yojson
                
  in
  match Petri_net.make_from_mol mol with
  | Some pnet ->
    let pnet_json = Petri_net.to_json pnet
    in
    `Assoc
      ["data", `Assoc [
          "mol", `String mol;
          "prot", prot_json;
          "pnet", pnet_json]]
  | None ->
    `Assoc ["data", `Assoc [
        "mol", `String mol;
        "prot", prot_json;
        "pnet", `Null 
      ]]
      

let build_all_from_prot prot : Yojson.Safe.t =
  let mol = Molecule.of_proteine prot
  in let  mol_json = `String mol in
  match Petri_net.make_from_mol mol with
  | Some pnet ->  let pnet_json = Petri_net.to_json pnet in
    `Assoc
      [
        "data", `Assoc [
          "mol", mol_json;
          "pnet", pnet_json]]
  | None ->
    `Assoc [
      "data", `Assoc [
        "mol", mol_json;
        "pnet", `Null
      ]
    ]
      
      
open Opium.Std

open Lwt.Infix
type build_req_body = 
  | Mol of Molecule.t
  | Prot of Proteine.t
[@@deriving yojson]

let build (req: Opium_kernel__Rock.Request.t) =
  match%lwt
    req.body
    |> Cohttp_lwt.Body.to_string
    >|= Yojson.Safe.from_string 
    >|= build_req_body_of_yojson
  with
  | Ok res ->
    `Json (
      match res with
      | Mol m -> (m |> build_all_from_mol)
      | Prot p -> p |> build_all_from_prot
    )  |> Lwt.return
  | Error e -> `Error e |> Lwt.return
                             


let acids_list  =
  let json_data =
    `Assoc
     ["purpose", `String "list_acids";
      "data", `List [
        `Assoc ["type", `String "places";
                "acids", `List (List.map Acid_types.acid_to_yojson Acid_types.Examples.nodes)];
        `Assoc ["type", `String "inputs_arcs";
                "acids", `List (List.map Acid_types.acid_to_yojson Acid_types.Examples.input_arcs)];
        `Assoc ["type", `String "outputs_arcs";
                "acids", `List (List.map Acid_types.acid_to_yojson Acid_types.Examples.output_arcs)];
        `Assoc ["type", `String "extensions";
                "acids", `List (List.map Acid_types.acid_to_yojson Acid_types.Examples.extensions);]]] in
   `Json json_data |> Lwt.return 


let make_routes simulator sandbox =
  [ get "/api/utils/acids", (fun x -> acids_list );
    post "/api/utils/build", (fun x -> build x) ]
  @ (Sandbox_req_handler.make_routes sandbox)

