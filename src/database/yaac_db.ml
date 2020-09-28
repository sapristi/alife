open Lwt.Infix
open Easy_logging_yojson
open Make_table
open Infix
open Ppx_deriving_yojson_runtime
let logger = Logging.get_logger "Yaac.Db"


module SandboxSig = MakeBaseTable(struct
    type data_type = Reactors.Sandbox.signature
    let table_name = "sandbox_sig"
    let data_type_to_yojson = Reactors.Sandbox.signature_to_yojson
    let data_type_of_yojson = Reactors.Sandbox.signature_of_yojson
  end)
module SandboxDump = MakeBaseTable(struct
    type data_type = Reactors.Sandbox.t
    let table_name = "sandbox_dump_dump"
    let data_type_to_yojson = Reactors.Sandbox.to_yojson
    let data_type_of_yojson = Reactors.Sandbox.of_yojson
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
  (* fun _ -> MolLibrary.setup_table (module Db) >>=? *)
  >|=? fun _ -> Ok conn


let init uri data_path =
  logger#info "Creating db at %s" uri;
  Caqti_lwt.connect (Uri.of_string uri)
  >>=? create_tables
  >>=? fun conn -> SandboxSig.load_dump_file conn (data_path ^ "/dump/signatures.json")
