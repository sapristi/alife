open Reactors
open Bacterie_libs
open Reaction
open Local_libs
open Base_chemistry
open Easy_logging_yojson
open Yaac_db__.Infix
open Lwt.Infix
let logger = Logging.get_logger "Yaac.Server.Sandbox"


open Opium.Std
open Lwt.Infix

let db_to_string_result res =
  match res with
  | Ok res -> Ok res
  | Error r -> Error (Caqti_error.show r)

(** /sandbox endopoints*)

let get_sandbox (sandbox : Sandbox.t) req =
  `Json(Sandbox.to_yojson sandbox) |> Lwt.return

let set_sandbox (sandbox : Sandbox.t) (req: Opium_kernel__Rock.Request.t)  =
  req.body
  |> Cohttp_lwt.Body.to_string
  >|= Yojson.Safe.from_string
  >|= Sandbox.signature_of_yojson
  >|= Result.map (fun signature -> Sandbox.set_from_signature sandbox signature)

(**  /sandbox/mol   endpoints*)

module Mol_req = struct

  (** generic result: bact *)
  let get_bact (sandbox : Sandbox.t) =
    `Json  (Bacterie.to_sig_yojson !(sandbox.bact))

  let add_mol (sandbox : Sandbox.t) (req) =
    let mol = param req "mol" in
    Bacterie.add_molecule mol !(sandbox.bact)
    |> Bacterie.execute_actions !(sandbox.bact);
    get_bact sandbox |> Lwt.return

  let remove_imol (sandbox : Sandbox.t) (req) =
    let mol = param req "mol" in
    Reactants_maps.IRMap.Ext.remove_all mol !(sandbox.bact).ireactants
    |> Bacterie.execute_actions !(sandbox.bact);
    get_bact sandbox |> Lwt.return

  let set_imol_quantity (sandbox : Sandbox.t) (req : Opium_kernel.Rock.Request.t) =
    let mol = param req "mol" in
    let uri = Uri.of_string req.request.resource in
    Uri.get_query_param uri "qtt"
    |> Option.to_result ~none:"Missing uri parameter qtt"
    |> Result.map (
      fun qtt_str ->
        let qtt = qtt_str |> int_of_string in
        Reactants_maps.IRMap.Ext.set_qtt qtt mol !(sandbox.bact).ireactants
        |> Bacterie.execute_actions !(sandbox.bact);
        get_bact sandbox
    ) |> fun res -> Lwt.return (`Res res)

  let pnet_ids_from_mol  (sandbox : Sandbox.t) (req) =
    let mol = param req "mol" in
    let pnet_ids = Reactants_maps.ARMap.get_pnet_ids mol !(sandbox.bact).areactants in
    let pnet_ids_json =
      `List (List.map (fun i -> `Int i) pnet_ids)
    in
    `Json (pnet_ids_json) |> Lwt.return

  let get_pnet (sandbox : Sandbox.t) (req) =
    let mol = param req "mol"
    and pnet_id = int_of_string (param req "pnet_id") in
    let pnet_json =
      (Reactants_maps.ARMap.find mol pnet_id !(sandbox.bact).areactants).pnet
      |> Petri_net.to_yojson
    in
    `Json pnet_json|> Lwt.return

  type pnet_action =
    | Update_token of (Token.t option) * int
    | Launch_transition of int
  [@@deriving yojson]

  let execute_pnet_action (sandbox: Sandbox.t) req =
    let mol = param req "mol"
    and pnet_id = int_of_string (param req "pnet_id") in

    req.body
    |> Cohttp_lwt.Body.to_string
    >|= Yojson.Safe.from_string
    >|= pnet_action_of_yojson
    >|=? (fun pnet_action ->
        let pnet = (Reactants_maps.ARMap.find mol pnet_id !(sandbox.bact).areactants).pnet in
        Ok (pnet_action, pnet))
    >|=? (
      fun (pnet_action, (pnet: Petri_net.t)) ->
        (
          match pnet_action with
          | Update_token (token_o, place_index) ->
            (
              (
                match token_o with
                | Some token ->
                  Place.set_token token pnet.places.(place_index);
                | None -> Place.remove_token pnet.places.(place_index);
              );
              Petri_net.update_launchables pnet;
            )
          | Launch_transition trans_index ->
            let p_actions = Petri_net.launch_transition_by_id trans_index pnet in
            let actions = List.map (fun x -> Reacs.T_effects x) [p_actions] in
            Bacterie.execute_actions !(sandbox.bact) actions;
        );
        let pnet_json = Petri_net.to_yojson pnet
        in Ok (`Json pnet_json)
    )
    >|= fun res -> `Res res

  let remove_amol (sandbox : Sandbox.t) (req) =
    let mol = param req "mol"
    and pnet_id = int_of_string (param req "pnet_id") in

    let amol = Reactants_maps.ARMap.find mol pnet_id  !(sandbox.bact).areactants in
    Reactants_maps.ARMap.remove amol !(sandbox.bact).areactants
    |> Bacterie.execute_actions !(sandbox.bact);
    get_bact sandbox |> Lwt.return

  let make_routes sandbox = [
    get,    "/amol/:mol",                 pnet_ids_from_mol sandbox;
    get,    "/amol/:mol/pnet/:pnet_id",   get_pnet sandbox;
    put,    "/amol/:mol/pnet/:pnet_id",   execute_pnet_action sandbox;
    delete, "/amol/:mol/pnet/:pnet_id",   remove_amol sandbox;

    put,    "/imol/:mol",                 set_imol_quantity sandbox;
    delete, "/imol/:mol",                 remove_imol sandbox;

    post,   "/mol/:mol",                  add_mol sandbox;
  ]
end

module Env_req = struct
  let get_environment (sandbox: Sandbox.t) (req) =
    logger#info "sandbox: %s" (Environment.show !(sandbox.env));
    logger#info "bact: %s" (Environment.show !(!(sandbox.bact).env));
    logger#info "reac_mgr: %s" (Environment.show !(!(sandbox.bact).reac_mgr.env));

    `Json (Environment.to_yojson !(sandbox.env))
    |> Lwt.return


  let set_environment (sandbox : Sandbox.t) (req: Opium_kernel__Rock.Request.t) =
    req.body
    |> Cohttp_lwt.Body.to_string
    >|= Yojson.Safe.from_string
    >|= Environment.of_yojson
    >|= Result.get_ok
    >|= fun env ->
    !(sandbox.bact).env := env;
    logger#debug "Commited new env: %s" (Environment.show env);
    `Json (Environment.to_yojson env)

  let make_routes sandbox = [
    get,    "/environment",               get_environment sandbox;
    put,    "/environment",               set_environment sandbox;
  ]
end

module Reactions_req = struct
  let get_reactions (sandbox : Sandbox.t) (req) =
    `Json( !(sandbox.bact).reac_mgr
           |> Reac_mgr.to_yojson) |> Lwt.return

  let next_reactions (sandbox : Sandbox.t) (req) =
    let n = param req "n" |> int_of_string
    in
    for i = 0 to n-1 do
      Bacterie.next_reaction !(sandbox.bact);
      (* Lwt_unix.sleep 0.001 *)
      logger#debug "step %i/%i" (i+1) n;
      Lwt_io.flush_all ()
    done;
    `Json (Bacterie.to_sig_yojson !(sandbox.bact)) |> Lwt.return

  let next_reactions_lwt (sandbox : Sandbox.t) (req) =
    let n = param req "n"
            |> int_of_string
    in
    for%lwt i = 0 to n-1 do
      Bacterie.next_reaction !(sandbox.bact);
      (* Lwt_unix.sleep 0.001 *)
      logger#debug "step %i/%i" (i+1) n;
      Lwt_io.flush_all ()
    done
    >|= (fun () ->
        `Json (Bacterie.to_sig_yojson !(sandbox.bact)))

  let make_routes sandbox = [
    get,    "/reaction",                  get_reactions sandbox;
    post,   "/reaction/next/:n",          next_reactions_lwt sandbox;
  ]
end

module SandboxSignature_req = struct

  type sig_item = {name: string; description: string; time: string}
  [@@deriving yojson]

  let get_bact_signatures db_conn req =
    Yaac_db.Sandbox.list db_conn
    >|=! List.map (fun (name, description, time) -> sig_item_to_yojson {name; description; time=Ptime.to_rfc3339 time})
    >|= fun data -> `Json (`List data)

  let get_signatures_dump db_conn req =
    Yaac_db.Sandbox.dump db_conn
    >|=! List.map Yaac_db.Sandbox.FullType.to_yojson
    >|= fun l -> `Json (`List l)

  type sig_post = (string * string * Sandbox.signature)
  [@@deriving yojson]

  let add_sig db_conn (req: Request.t) =
    req.body
    |> Cohttp_lwt.Body.to_string
    >|= Yojson.Safe.from_string
    >|= sig_post_of_yojson
    >>=? (fun sig_post -> (
          (Yaac_db.Sandbox.add_one db_conn sig_post)
          >|= Result.map_error Caqti_error.show
        ))
    >|=? (fun () -> Ok `Empty)
    >|= fun res -> `Res res

    (* Set the current sandbox from the stored signature;
       Reset the Random seed from that of the sig.contents

       TODO: it could be nice that the sandbox stores a random generator for itself.   *)
  let set_from_sig_name (sandbox : Sandbox.t) db_conn req =
    let sig_name = param req "name" in
    Yaac_db.Sandbox.find_opt db_conn sig_name
    >|=! Option.to_result ~none:("Cannot find "^sig_name)
    >|=? (fun (_,_,_,sandbox_sig) ->
        Sandbox.set_from_signature sandbox sandbox_sig;
        Random.init sandbox_sig.seed;
        Ok `Empty)
    >|= fun res -> `Res res

  let make_routes sandbox db = [
    get,    "/signature",                    get_bact_signatures db;
    get,    "/signature/dump",               get_signatures_dump db;
    post,   "/signature",                    add_sig db;
    post,   "/signature/:name/load",         set_from_sig_name sandbox db;
  ]
end

let make_routes sandbox db =
  [ get,    "", get_sandbox sandbox]
  @ (Mol_req.make_routes sandbox)
  @ (Env_req.make_routes sandbox)
  @ (Reactions_req.make_routes sandbox)
  @ (SandboxSignature_req.make_routes sandbox db)
