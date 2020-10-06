open Lwt.Infix
open Easy_logging_yojson
open Make_table
open Infix
open Ppx_deriving_yojson_runtime
let logger = Logging.get_logger "Yaac.Db"


module SandboxSig = MakeBaseTable(struct
    type data_type = Reactors.Sandbox.signature
    [@@deriving yojson]
    let table_name = "sandbox_sig"
  end)

module SandboxDump = MakeBaseTable(struct
    type data_type = Reactors.Sandbox.t
    [@@deriving yojson]
    let table_name = "sandbox_dump_dump"
  end)

module BactSig = MakeBaseTable(struct
    type data_type = Bacterie_libs.Bacterie.bact_sig
    [@@deriving yojson]
    let table_name = "bact_sigs"
  end)

module Environment = MakeBaseTable(struct
    type data_type = Bacterie_libs.Environment.t
    let data_type_of_yojson = Bacterie_libs.Environment.of_yojson
    let data_type_to_yojson = Bacterie_libs.Environment.to_yojson
    let table_name = "environment"
  end)

(* module MolLibrary = MakeBaseTable(struct
 *     type data_type = string
 *     let table_name = "mol_library"
 *     let encode_data x = Ok x
 *     let decode_data x = Ok x
 *   end) *)

let create_tables conn =
  SandboxSig.setup_table conn
  >>=? fun _ -> SandboxDump.setup_table conn
  >>=? fun _ -> BactSig.setup_table conn
  >>=? fun _ -> Environment.setup_table conn
  (* fun _ -> MolLibrary.setup_table (module Db) >>=? *)
  >|=? fun _ -> Ok conn


let init uri data_path =
  logger#info "Creating db at %s" uri;
  let open Lwt.Infix in
  Caqti_lwt.connect (Uri.of_string uri)
  >|= log_res_debug logger "conn"
  >>=? create_tables
  >|= log_res_debug logger "tables"
  >>=? fun conn -> BactSig.load_dump_file conn (data_path ^ "/dump/bact_sigs.json")
  >|= log_res_debug logger "load 1"
  >>=? fun conn -> Environment.load_dump_file conn (data_path ^ "/dump/envs.json")
  >|= log_res_debug logger "load 2"

