
open Reactors
open Bacterie_libs
open Reaction
open Local_libs
open Base_chemistry
open Easy_logging_yojson
let logger = Logging.get_logger "Yaac.Server.sandbox"
(* let logger = Logging.make_logger "Server.Sandbox" Debug [Cli Debug];; *)

(* logger#warning "WTF";; *)

open Opium.Std
open Lwt.Infix

(** /sandbox endopoints*)

let get_sandbox (sandbox : Sandbox.t) req =
  `Json(
    `Assoc [
      "data", (Sandbox.to_yojson sandbox)])
    |> Lwt.return 
  
let reset_sandbox (sandbox : Sandbox.t) req =
  let data_json =  Yojson.Safe.from_file "bact.json" in
  let new_sandbox = Sandbox.of_yojson data_json in
  sandbox.bact := !(new_sandbox.bact);
  sandbox.env := !(new_sandbox.env);
  get_sandbox sandbox req

let set_sandbox (sandbox : Sandbox.t) (req: Opium_kernel__Rock.Request.t)  =
  let%lwt new_sandbox = 
    req.body
    |> Cohttp_lwt.Body.to_string
    >|= Yojson.Safe.from_string
    >|= Sandbox.of_yojson
  in
  (
    sandbox.bact := !(new_sandbox.bact);
    sandbox.env  := !(new_sandbox.env);
    get_sandbox sandbox req
  )

(**  /sandbox/mol   endpoints*)

let get_bact_elements (sandbox : Sandbox.t) req =
  `Json (`Assoc
    ["purpose", `String "bact_elements";
     "data", (Bacterie.to_sig_yojson !(sandbox.bact))]
        )  |> Lwt.return



let pnet_ids_from_mol  (sandbox : Sandbox.t) (req) =
  let mol = param req "mol" in
  let pnet_ids = Reactants_maps.ARMap.get_pnet_ids mol !(sandbox.bact).areactants in
  let pnet_ids_json =
    `List (List.map (fun i -> `Int i) pnet_ids)
  in
  `Json (
    `Assoc
      ["purpose", `String "pnet_ids";
    "data", pnet_ids_json]
  ) |> Lwt.return 

let add_mol (sandbox : Sandbox.t) (req) = 
  let mol = param req "mol" in
  Bacterie.add_molecule mol !(sandbox.bact)
  |> Bacterie.execute_actions !(sandbox.bact);
  get_bact_elements sandbox req

let remove_imol (sandbox : Sandbox.t) (req) = 
  let mol = param req "mol" in
  Reactants_maps.IRMap.Ext.remove_all mol !(sandbox.bact).ireactants
  |> Bacterie.execute_actions !(sandbox.bact);
  get_bact_elements sandbox req

let set_imol_quantity (sandbox : Sandbox.t) (req : Opium_kernel.Rock.Request.t) =
  let uri = Uri.of_string req.request.resource in
  match Uri.get_query_param uri "qtt" with
  | None ->
    `Error "bad parameters" |> Lwt.return
  | Some n' ->
    let n = int_of_string n' in
    let mol = param req "mol"
    in
    Reactants_maps.IRMap.Ext.set_qtt n mol !(sandbox.bact).ireactants
    |> Bacterie.execute_actions !(sandbox.bact);
    get_bact_elements sandbox req
      

(** /sandbox/mol/:mol/pnet endpoints *)


let get_pnet (sandbox : Sandbox.t) (req) =
  let mol = param req "mol"
  and pnet_id = int_of_string (param req "pnet_id") in
  let pnet_json =
    (Reactants_maps.ARMap.find mol pnet_id !(sandbox.bact).areactants).pnet
    |> Petri_net.to_json
  in
  `Json (`Assoc
             ["purpose", `String "pnet_from_mol";
              "data",  `Assoc ["pnet", pnet_json]] 
           )  |> Lwt.return 



type pnet_action =
  | Update_token of (Token.t option) * int
  | Launch_transition of int
[@@deriving yojson]
      
let pnet_action (sandbox: Sandbox.t) req =
  let mol = param req "mol"
  and pnet_id = int_of_string (param req "pnet_id") in

  match%lwt 
    req.body
    |> Cohttp_lwt.Body.to_string
    >|= Yojson.Safe.from_string
    >|= pnet_action_of_yojson
  with
  | Error s -> Lwt.return (`Error "error decoding token")
  | Ok action -> match action with
    | Update_token (token_o, place_index) ->
     (
       let pnet = (Reactants_maps.ARMap.find mol pnet_id !(sandbox.bact).areactants).pnet in
       (
         match token_o with
         | Some token -> 
            Place.set_token token pnet.places.(place_index);
         | None -> Place.remove_token pnet.places.(place_index);
       );
       Petri_net.update_launchables pnet;
       
       let pnet_json = Petri_net.to_json pnet in
         `Json (`Assoc
            ["purpose", `String "pnet_update";
             "data",  `Assoc ["pnet", pnet_json]]   
         )  |> Lwt.return
     )
    | Launch_transition trans_index -> 

      let pnet = (Reactants_maps.ARMap.find mol pnet_id !(sandbox.bact).areactants).pnet in
      
      let p_actions = Petri_net.launch_transition_by_id trans_index pnet in
      let actions = List.map (fun x -> Reacs.T_effects x) [p_actions] in
      Bacterie.execute_actions !(sandbox.bact) actions;
      
      let pnet_json = Petri_net.to_json pnet
      in
      `Json (
        `Assoc
          ["purpose", `String "pnet_update";
           "data",  `Assoc ["pnet", pnet_json]]  
      ) |> Lwt.return
             
let remove_amol (sandbox : Sandbox.t) (req) = 
  let mol = param req "mol"
  and pnet_id = int_of_string (param req "pnet_id") in

  let amol = Reactants_maps.ARMap.find mol pnet_id  !(sandbox.bact).areactants in
  Reactants_maps.ARMap.remove amol !(sandbox.bact).areactants
  |> Bacterie.execute_actions !(sandbox.bact);
  get_bact_elements sandbox req

               
(*
  and save_state bact =
    let data_json = Bacterie.to_json bact in
    Yojson.Safe.to_file "bact.json" data_json;
    "state saved"
 *)
let get_environment (sandbox: Sandbox.t) (req) =
  logger#info "sandbox: %s" (Environment.show !(sandbox.env));
  logger#info "bact: %s" (Environment.show !(!(sandbox.bact).env));
  logger#info "reac_mgr: %s" (Environment.show !(!(sandbox.bact).reac_mgr.env));

  `Json (Environment.to_yojson !(sandbox.env))
  |> Lwt.return


let set_environment (sandbox : Sandbox.t) (req: Opium_kernel__Rock.Request.t) =
  match%lwt
    req.body
    |> Cohttp_lwt.Body.to_string
    >|= Yojson.Safe.from_string
    >|= Environment.of_yojson
  with
  | Ok env ->
     !(sandbox.bact).env := env;
     logger#debug "Commited new env: %s" (Environment.show env);
     `String "done" |> Lwt.return
  | Error s ->
     (`Error ("error decoding env from json " ^ s)) |> Lwt.return


let get_reactions (sandbox : Sandbox.t) (req) =
   
  `Json( !(sandbox.bact).reac_mgr
         |> Reac_mgr.to_yojson) |> Lwt.return
                                     

let next_reactions (sandbox : Sandbox.t) (req) =
  let n = param req "n"
          |> int_of_string
  in
  (
    try
      for i = 0 to n-1 do
        Bacterie.next_reaction !(sandbox.bact);
      done;
    with
    | _ as e->
      logger#error "Error when picking reaction;\n%s\n%s"
        (Printexc.get_backtrace ()) (Printexc.to_string e);
      ();
  );
  `Json (`Assoc
    ["purpose", `String "bactery_update_desc";
     "data", (Bacterie.to_sig_yojson !(sandbox.bact))]) |> Lwt.return

(* let show_pnet (sandbox : Sandbox.t) (cgi : Netcgi.cgi) =
 *   let mol =cgi#argument_value "mol"
 *   and pnet_id = int_of_string @@ cgi#argument_value "pnet_id"  in
 *   let ar = Reactants_maps.ARMap.find mol pnet_id !(sandbox.bact).areactants in
 *   let pnet = ar.pnet in 
 *   Petri_net.show pnet *)




let get_bact_states _ =
  `Json (`List (
      !Sandbox.bact_states
      |> List.map (fun (n,_) -> `String n)
    )) |> Lwt.return


let from_bact_state (sandbox : Sandbox.t) req =
  let state_name = param req "name" in
  Sandbox.update_from_state sandbox state_name;
  `Empty |> Lwt.return
  

let make_routes sandbox =
  [ get    "/api/sandbox",                           get_sandbox sandbox ;
    post   "/api/sandbox",                           set_sandbox sandbox ;
    post   "/api/sandbox/reset",                     reset_sandbox sandbox;

    get    "/api/sandbox/amol",                      get_bact_elements sandbox; 
    get    "/api/sandbox/amol/:mol",                 pnet_ids_from_mol sandbox;
    get    "/api/sandbox/amol/:mol/pnet/:pnet_id",   get_pnet sandbox;
    put    "/api/sandbox/amol/:mol/pnet/:pnet_id",   pnet_action sandbox;
    delete "/api/sandbox/amol/:mol/pnet/:pnet_id",   remove_amol sandbox;

    get    "/api/sandbox/imol",                      get_bact_elements sandbox;
    put    "/api/sandbox/imol/:mol",                 set_imol_quantity sandbox;
    delete "/api/sandbox/imol/:mol",                 remove_imol sandbox;

    get    "/api/sandbox/mol",                       get_bact_elements sandbox; 
    post   "/api/sandbox/mol/:mol",                  add_mol sandbox;

    get    "/api/sandbox/environment",                   get_environment sandbox;
    put    "/api/sandbox/environment",               set_environment sandbox;
    get    "/api/sandbox/reaction",                  get_reactions sandbox;
    post   "/api/sandbox/reaction/next/:n",          next_reactions sandbox;

    get    "/api/sandbox/state",                    get_bact_states ;
    put    "/api/sandbox/state/:name",               from_bact_state sandbox;
  ]
