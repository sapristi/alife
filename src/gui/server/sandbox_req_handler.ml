open Reactors
open Bacterie_libs
open Reaction
open Local_libs
open Base_chemistry
open Easy_logging_yojson
open Yaac_db__.Infix
open Lwt.Infix
let logger = Logging.get_logger "Yaac.Server.Sandbox"


let db_to_string_result res =
  match res with
  | Ok res -> Ok res
  | Error r -> Error (Caqti_error.show r)

(** /sandbox endopoints*)

let get_sandbox (sandbox : Sandbox.t) req =
  `Json(Sandbox.to_yojson sandbox) |> Lwt.return

let set_sandbox (sandbox : Sandbox.t) (req: Opium.Request.t)  =
  req
  |> Opium.Request.to_json_exn
  >|= Sandbox.signature_of_yojson
  >|= Result.map (fun signature -> Sandbox.set_from_signature sandbox signature)

(**  /sandbox/mol   endpoints*)

module Mol_req = struct

  (** generic result: bact *)
  let get_bact (sandbox : Sandbox.t) =
    `Json  (Bacterie.to_sig_yojson !sandbox)

  let add_mol (sandbox : Sandbox.t) (req) =
    let mol = Opium.Request.query_exn "mol" req in
    Bacterie.add_molecule mol !sandbox
    |> Bacterie.execute_actions !sandbox;
    get_bact sandbox |> Lwt.return

  let remove_imol (sandbox : Sandbox.t) (req) =
    let mol = Opium.Request.query_exn "mol" req in
    Reactants_maps.IRMap.Ext.remove_all mol !sandbox.ireactants
    |> Bacterie.execute_actions !sandbox;
    get_bact sandbox |> Lwt.return

  let set_imol_quantity (sandbox : Sandbox.t) (req : Opium.Request.t) =
    let mol = Opium.Request.query_exn "mol" req in
    let qtt_str = Opium.Request.query_exn "qtt" req in
    let qtt = qtt_str |> int_of_string in
    Reactants_maps.IRMap.Ext.set_qtt qtt mol !sandbox.ireactants
    |> Bacterie.execute_actions !sandbox;
    get_bact sandbox
    |> Lwt.return

  let pnet_ids_from_mol  (sandbox : Sandbox.t) (req) =
    let mol = Opium.Request.query_exn "mol" req in
    let pnet_ids = Reactants_maps.ARMap.get_pnet_ids mol !sandbox.areactants in
    let pnet_ids_json =
      `List (List.map (fun i -> `Int i) pnet_ids)
    in
    `Json (pnet_ids_json) |> Lwt.return

  let get_pnet (sandbox : Sandbox.t) (req) =
    let mol = Opium.Request.query_exn "mol" req
    and pnet_id = Opium.Request.query_exn "pnet_id" req |> int_of_string in
    let pnet_json =
      (Reactants_maps.ARMap.find mol pnet_id !sandbox.areactants).pnet
      |> Petri_net.to_yojson
    in
    `Json pnet_json|> Lwt.return

  type pnet_action =
    | Update_token of (Token.t option) * int
    | Launch_transition of int
  [@@deriving yojson]

  let execute_pnet_action (sandbox: Sandbox.t) req =
    let mol = Opium.Request.query_exn "mol" req
    and pnet_id = Opium.Request.query_exn "pnet_id" req |> int_of_string in

    req
    |> Opium.Request.to_json_exn
    >|= pnet_action_of_yojson
    >|=? (fun pnet_action ->
        let pnet = (Reactants_maps.ARMap.find mol pnet_id !sandbox.areactants).pnet in
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
            Bacterie.execute_actions !sandbox actions;
        );
        let pnet_json = Petri_net.to_yojson pnet
        in Ok (`Json pnet_json)
    )
    >|= fun res -> `Res res

  let remove_amol (sandbox : Sandbox.t) (req) =
    let mol = Opium.Request.query_exn "mol" req
    and pnet_id = Opium.Request.query_exn "pnet_id" req |> int_of_string in

    let amol = Reactants_maps.ARMap.find mol pnet_id  !sandbox.areactants in
    Reactants_maps.ARMap.remove amol !sandbox.areactants
    |> Bacterie.execute_actions !sandbox;
    get_bact sandbox |> Lwt.return

  let make_routes sandbox = [
    Opium.Request.get,    "/amol/:mol",                 pnet_ids_from_mol sandbox;
    Opium.Request.get,    "/amol/:mol/pnet/:pnet_id",   get_pnet sandbox;
    Opium.Request.put,    "/amol/:mol/pnet/:pnet_id",   execute_pnet_action sandbox;
    Opium.Request.delete, "/amol/:mol/pnet/:pnet_id",   remove_amol sandbox;

    Opium.Request.put,    "/imol/:mol",                 set_imol_quantity sandbox;
    Opium.Request.delete, "/imol/:mol",                 remove_imol sandbox;

    Opium.Request.post,   "/mol/:mol",                  add_mol sandbox;
  ]
end

module Env_req = struct
  let get_environment (sandbox: Sandbox.t) (req) =
    logger#info "sandbox: %s" (Environment.show !(!sandbox.env));
    logger#info "bact: %s" (Environment.show !(!sandbox.env));
    logger#info "reac_mgr: %s" (Environment.show !(!sandbox.reac_mgr.env));

    `Json (Environment.to_yojson !(!sandbox.env))
    |> Lwt.return


  let set_environment (sandbox : Sandbox.t) (req: Opium.Request.t) =
    req
    |> Opium.Request.to_json_exn
    >|= Environment.of_yojson
    >|= Result.get_ok
    >|= fun env ->
    !sandbox.env := env;
    logger#debug "Bact env %s" (Environment.show !(!sandbox.env));
    logger#debug "Sandbox env %s" (Environment.show !(!sandbox.env));

    logger#debug "Commited new env: %s" (Environment.show env);
    `Json (Environment.to_yojson env)

  let make_routes sandbox = [
    Opium.Request.get,    "/environment",               get_environment sandbox;
    Opium.Request.put,    "/environment",               set_environment sandbox;
  ]
end

module Reactions_req = struct
  let get_reactions (sandbox : Sandbox.t) (req) =
    `Json( !sandbox.reac_mgr
           |> Reac_mgr.to_yojson) |> Lwt.return

  let next_reactions (sandbox : Sandbox.t) (req) =
    let n = Opium.Request.query_exn "n" req |> int_of_string
    in
    for i = 0 to n-1 do
      Bacterie.next_reaction !sandbox;
      (* Lwt_unix.sleep 0.001 *)
      logger#debug "step %i/%i" (i+1) n;
      Lwt_io.flush_all ()
    done;
    `Json (Bacterie.to_sig_yojson !sandbox) |> Lwt.return

  let next_reactions_lwt (sandbox : Sandbox.t) (req) =
    let n = Opium.Request.query_exn "n" req |> int_of_string
    in
    for%lwt i = 0 to n-1 do
      Bacterie.next_reaction !sandbox;
      (* Lwt_unix.sleep 0.001 *)
      logger#debug "step %i/%i" (i+1) n;
      Lwt_io.flush_all ()
    done
    >|= (fun () ->
        `Json (Bacterie.to_sig_yojson !sandbox))

  let make_routes sandbox = [
    Opium.Request.get,    "/reaction",                  get_reactions sandbox;
    Opium.Request.post,   "/reaction/next/:n",          next_reactions_lwt sandbox;
  ]
end

module BactSignatureDB_req = struct

  include Yaac_db.BactSig.RequestHandler
  let set_from_sig_name (sandbox : Sandbox.t) db_conn req =
    let sig_name = Opium.Request.query_exn "name" req in
    Yaac_db.BactSig.find_res (db_conn ()) sig_name
    >|=? (fun ({data; _}: Yaac_db.BactSig.FullType.t) ->
        sandbox := Bacterie.from_sig data ~env:!(!sandbox.env) ~randstate:!(!sandbox.randstate);
        Ok `Empty)
    >|= fun res -> `Res res

  type post_item = {name: string; description: string;}
  [@@deriving yojson]

  let add (sandbox : Sandbox.t) db_conn (req: Opium.Request.t) =
    req
    |> Opium.Request.to_json_exn
    >|= post_item_of_yojson
    >|= Result.get_ok
    >>= (fun ({name; description}) -> (
          (Yaac_db.BactSig.insert_or_replace (db_conn ())
             (name, description, Bacterie.to_sig !sandbox))
          >|= Result.get_ok
        ))
    >|= (fun () -> `Empty)

  let make_routes sandbox db = [
    Opium.Request.get,    "/db/bactsig",                    list db;
    Opium.Request.get,    "/db/bactsig/dump",               dump db;
    Opium.Request.post,   "/db/bactsig",                    add sandbox db;
    Opium.Request.post,   "/db/bactsig/:name/load",         set_from_sig_name sandbox db;
    Opium.Request.delete,   "/db/bactsig/:name",            delete_one db;
  ]
end


module EnvDB_req = struct

  include Yaac_db.Environment.RequestHandler

  let load_env (sandbox : Sandbox.t) db_conn req =
    let env_name = Opium.Request.query_exn "name" req in
    Yaac_db.Environment.find_res (db_conn ()) env_name
    >|=? (fun {data; _} ->
        !sandbox.env := data;
        Ok `Empty)
    >|= fun res -> `Res res

  type post_item = {name: string; description: string; data: Bacterie_libs.Environment.t}
  [@@deriving yojson]

  let add  db_conn (req: Opium.Request.t) =
    req
    |> Opium.Request.to_json_exn
    >|= post_item_of_yojson
    >|= Result.get_ok
    >>= (fun ({name; description; data}) -> 
          (Yaac_db.Environment.insert_or_replace (db_conn ())
             (name, description, data)
          >|= Result.get_ok
        ))
    >|= (fun () -> `Empty)

  let make_routes sandbox db = [
    Opium.Request.get,    "/db/environment",                    list db;
    Opium.Request.get,    "/db/environment/dump",               dump db;
    Opium.Request.post,   "/db/environment",                    add  db;
    Opium.Request.post,   "/db/environment/:name/load",         load_env sandbox db;
    Opium.Request.delete, "/db/environment/:name",            delete_one db;
  ]
end



module MolLibrary_req = struct

  include Yaac_db.MolLibrary.RequestHandler

  type post_item = {name: string; description: string; data: string}
  [@@deriving yojson]

  let add  (sandbox : Sandbox.t) db_conn (req: Opium.Request.t) =
    req
    |> Opium.Request.to_json_exn
    >|= post_item_of_yojson
    >|= Result.get_ok
    >>= (fun ({name; description; data}) -> (
          (Yaac_db.MolLibrary.insert_or_replace (db_conn ()) (name, description, data))
          >|= Result.get_ok
        ))
    >|= (fun () -> `Empty)

  let make_routes sandbox db_conn = [
    Opium.Request.get,    "/db/mol_library",                    list db_conn;
    Opium.Request.get,    "/db/mol_library/dump",               dump db_conn;
    Opium.Request.post,   "/db/mol_library",                    add sandbox db_conn;
    Opium.Request.get,    "/db/mol_library/:name",            find_one db_conn;
    Opium.Request.delete, "/db/mol_library/:name",            delete_one db_conn;
  ]
end



let make_routes sandbox db_conn =
  [ Opium.Request.get,    "", get_sandbox sandbox]
  @ (Mol_req.make_routes sandbox)
  @ (Env_req.make_routes sandbox)
  @ (Reactions_req.make_routes sandbox)
  @ (BactSignatureDB_req.make_routes sandbox db_conn)
  @ (EnvDB_req.make_routes sandbox db_conn)
  @ (MolLibrary_req.make_routes sandbox db_conn)
