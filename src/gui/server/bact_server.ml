(* * simulation server *)

(* ** preamble*)
open Sim_req_handler
open Sandbox_req_handler
open Bacterie_libs
open Reactors
   

open Logs
let src = Logs.Src.create "mylib.network" ~doc:"logs mylib's network events"  
module Log = (val Logs.src_log src : Logs.LOG)
           
open Local_libs
  
           
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
      
let list_acids cgi : string =
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
    

let server_functions =
  ["prot_from_mol", prot_from_mol;
   "build_all_from_mol", build_all_from_mol;
   "build_all_from_prot", build_all_from_prot;
   "list_acids", list_acids]
    
  
let make_dyn_service  f  =
  let reporter : Reporter.t ={
      Reporter.loggers = [Reporter.cli_logger; Reporter.make_file_logger "server"];
      Reporter.prefix = (fun () -> "");
      Reporter.suffix = (fun () -> "");
    } in 
  Nethttpd_services.dynamic_service
    { dyn_handler =
        (fun env (cgi:Netcgi.cgi)  ->
          let req_descr = List.fold_left
                    (fun res x->
                      res ^(Printf.sprintf "\t%s : %s\n" x#name x#value))
                    ""
                    (cgi#arguments)
          in

          Log.info (fun m -> m "serving GET request : \n%s" req_descr); 
          Reporter.report reporter (Printf.sprintf
                                      "serving GET request : \n%s" req_descr);
          
          let response = f cgi in
          
          cgi # set_header ~content_type:"application/json" ();
          cgi # out_channel # output_string response;
          cgi # out_channel # commit_work();

          Reporter.report reporter (Printf.sprintf
                                      "sent response : \n%s" response);
          
          Log.info (fun m -> m "sent response :%s\n" response);
        );
      dyn_activation = Nethttpd_services.std_activation `Std_activation_buffered;
      dyn_uri = None;
      dyn_translator = (fun _ -> "");
      dyn_accept_all_conditionals = false
    }


let make_req_handler simulator sandbox =

  let main_redirects =
    (List.map
       (fun (name, f) ->  "/sim_commands/general/"^name, make_dyn_service f)
       server_functions)
  and sandbox_redirects = 
    (List.map
       (fun (name, f) ->  "/sim_commands/sandbox/"^name, make_dyn_service (f sandbox))
       Sandbox_req_handler.server_functions)
  and simulator_redirect = 
    (List.map
       (fun (name, f) ->  "/sim_commands/simulator/"^name, make_dyn_service  (f simulator))
       Sim_req_handler.server_functions)

  in 

    Nethttpd_services.uri_distributor
      (
        main_redirects @
          sandbox_redirects @
            simulator_redirect)
  
