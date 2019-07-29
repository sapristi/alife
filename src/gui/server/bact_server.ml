(* * simulation server *)

(* ** preamble*)
open Sim_req_handler
open Sandbox_req_handler
open Bacterie_libs
open Reactors
open Local_libs   
open Easy_logging_yojson
let logger = Logging.get_logger "Server.Bact"


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

let prot_from_mol (cgi:Netcgi.cgi) : string =
  
  let prot_json =
    cgi # argument_value "mol_desc"
    |> Molecule.to_proteine
    |> Proteine.to_yojson
    
  in
  `Assoc  ["purpose", `String "prot_from_mol";
           "data", `Assoc ["prot", prot_json]] 
  |> Yojson.Safe.to_string


  
let build_all_from_mol (cgi : Netcgi.cgi) : string =
  
  let mol = cgi # argument_value "mol_desc" in
  let prot_json = mol
                  |> Molecule.to_proteine
                  |> Proteine.to_yojson
                
  in
  match Petri_net.make_from_mol mol with
  | Some pnet -> let pnet_json = Petri_net.to_json pnet
                 in
                 `Assoc
                  ["purpose", `String "build_all_from_mol";
                   "data", `Assoc ["prot", prot_json;
                                   "pnet", pnet_json]]
                 |> Yojson.Safe.to_string
  | None -> "cannot build pnet"
          
let build_all_from_prot (cgi : Netcgi.cgi) : string =
  
  match 
    cgi # argument_value "prot_desc"
    |> Yojson.Safe.from_string
    |> Proteine.of_yojson 
  with
  | Ok prot ->
    let mol = Molecule.of_proteine prot
    in let  mol_json = `String mol in
    (
      match Petri_net.make_from_mol mol with
      | Some pnet ->  let pnet_json = Petri_net.to_json pnet in
        `Assoc
          ["purpose", `String "build_all_from_prot";
           "data",
           `Assoc ["mol", mol_json; "pnet", pnet_json]]
        |>  Yojson.Safe.to_string
      | None -> "cannot build pnet"
    )
  | Error s -> 
    "error decoding proteine from json : "^s

open Opium.Std

type build_req_body = 
  | Mol of Molecule.t
  | Prot of Proteine.t
[@@deriving yojson]

open Lwt.Infix

   
let build (req: Opium_kernel__Rock.Request.t) =
  (
    match%lwt
      req.body
      |> Cohttp_lwt.Body.to_string
      >|= Yojson.Safe.from_string 
      >|= build_req_body_of_yojson
    with
    | Ok res -> Lwt.return (`String "body decoded")
    | Error e -> Lwt.return (`String ("bad body"^e))
  )


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
  Yojson.Safe.to_string json_data
    


let respond_json = respond' ~headers:( Cohttp.Header.init_with "Content-Type" "application/json")
let make_routes simulator sandbox x =
  x
  |> get "/ok" (fun x -> `String "ok" |> respond')
  |> get "/api/utils/acids" (fun x -> `String acids_list |> respond_json)
  |> post "/api/utils/build" (fun x -> (build x) >|=  respond)
  |> get "/raise" (fun x -> failwith "this is an error" |> respond')


(* let response, status =
 *   try 
 *     f cgi, `Ok
 *   with
 *   | _ as e ->
 *      logger#error "An error happened while treating the request:%s\n%s"
 *        (Printexc.get_backtrace ())
 *        (Printexc.to_string e);
 *      
 *      "error", `Internal_server_error *)
