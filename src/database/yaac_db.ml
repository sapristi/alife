open Lwt.Infix
open Easy_logging_yojson
open Make_table
open Infix
open Ppx_deriving_yojson_runtime
let logger = Logging.get_logger "Yaac.Db"


module Sandbox = MakeBaseTable(struct
    type data_type = Reactors.Sandbox.signature
    let table_name = "sandbox"
    let init_values = []
    let encode_data x = Ok (x |> Reactors.Sandbox.signature_to_yojson |> Yojson.Safe.to_string)
    let decode_data x : (data_type, string) result = x |> Yojson.Safe.from_string |> Reactors.Sandbox.signature_of_yojson
  end)
module StateDump = MakeBaseTable(struct
    type data_type = string
    let table_name = "stat_dump"
    let init_values = []
    let encode_data x = Ok x
    let decode_data x = Ok x
  end)
module MolLibrary = MakeBaseTable(struct
    type data_type = string
    let table_name = "mol_library"
    let init_values = []
    let encode_data x = Ok x
    let decode_data x = Ok x
  end)

let create_tables (module Db : Caqti_lwt.CONNECTION) =
  Sandbox.setup_table (module Db) >>=?
  fun _ -> StateDump.setup_table (module Db) >>=?
  fun _ -> MolLibrary.setup_table (module Db) >>=?
  fun _ -> Ok (module Db: Caqti_lwt.CONNECTION) |> Lwt.return


let init uri  sandbox_init =

  logger#info "Creating db at %s" uri;
  Caqti_lwt.connect (Uri.of_string uri)
  >>=? create_tables
  >>=? Sandbox.populate_static sandbox_init
