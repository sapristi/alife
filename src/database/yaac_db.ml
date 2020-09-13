open Lwt.Infix
open Easy_logging_yojson
open Make_table

let logger = Logging.get_logger "Yaac.Db"

let (>>=?) m f =
  m >>= (function | Ok x -> f x | Error err ->  logger#serror (Caqti_error.show err); Lwt.return (Error err))

let (>>==) m f =
  m >>= (function | Ok x -> f x | Error err -> logger#serror (Caqti_error.show err); Lwt.return ())


module Sandbox = MakeBaseTable(struct
    type data_type = Reactors.Sandbox.t
    let table_name = "sandbox"
    let init_values = []
    let encode_data x = Ok (x |> Reactors.Sandbox.to_yojson |> Yojson.Safe.to_string)
    let decode_data x = Ok (x |> Yojson.Safe.from_string |> Reactors.Sandbox.of_yojson)
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
  fun () -> StateDump.setup_table (module Db) >>=?
  fun () -> MolLibrary.setup_table (module Db) >>=?
  fun () -> Ok (module Db: Caqti_lwt.CONNECTION) |> Lwt.return


let init uri sandbox_init =
  logger#info "Creating db at %s" uri;
  Caqti_lwt.connect (Uri.of_string uri)
  >>=? create_tables
  >>=? Sandbox.populate_static sandbox_init
  >|= (function
      | Ok _ -> ()
      | Error err -> logger#serror (Caqti_error.show err); ())
