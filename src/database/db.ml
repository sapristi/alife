open Lwt.Infix
open Easy_logging_yojson

let logger = Logging.get_logger  "Yaac.Db"
let (>>=?) m f =
  m >>= (function | Ok x -> f x | Error err -> Lwt.return (Error err))


module MakeBaseTable (TableParams: sig val table_name: string end) = struct
  module Full = struct
    type t = {
      name: string;
      description: string;
      ts: Ptime.t;
      data: string
    }

    let t =
      let encode {name; description; ts; data} = Ok (name, description, ts, data) in
      let decode (name, description, ts, data) = Ok {name; description; ts; data} in
      let rep = Caqti_type.(tup4 string string ptime string) in
      Caqti_type.custom ~encode ~decode rep

  end

  module Partial = struct
    type t = {
      name: string;
      description: string;
      ts: Ptime.t;
    }

    let t =
      let encode {name; description; ts} = Ok (name, description, ts) in
      let decode (name, description, ts) = Ok {name; description; ts} in
      let rep = Caqti_type.(tup3 string string ptime) in
      Caqti_type.custom ~encode ~decode rep
  end

  let create_table = Caqti_request.exec Caqti_type.unit [%string {eot|
CREATE TABLE IF NOT EXISTS %{TableParams.table_name} (
  name TEXT PRIMARY KEY,
  description TEXT NOT NULL,
  ts TIME NOT NULL,
  data TEXT NOT NULL
) WITHOUT ROWID
|eot} ]

  let add_one = Caqti_request.exec
      Full.t
      [%string {|
INSERT INTO %{TableParams.table_name}
(name, description, date, data) VALUES (?, ?, ?, ?)
|} ]

  let get_opt = Caqti_request.find_opt
      Caqti_type.string Full.t
      [%string "SELECT * FROM %{TableParams.table_name} WHERE name = ?" ]

  let list = Caqti_request.collect
      Caqti_type.unit Partial.t
      [%string "SELECT * FROM %{TableParams.table_name} WHERE NOT stolen IS NULL" ]
end

module Sandbox = MakeBaseTable(struct let table_name = "sandbox" end)
module StateDump = MakeBaseTable(struct let table_name = "stat_dump" end)
module MolLibrary = MakeBaseTable(struct let table_name = "mol_library" end)

let create_tables (module Db : Caqti_lwt.CONNECTION) =
  Db.exec Sandbox.create_table ()
  >>=? fun () -> Db.exec StateDump.create_table ()
  >>=? fun () -> Db.exec MolLibrary.create_table ()

let init uri =
  logger#info "Creating db at %s" uri;
  Caqti_lwt.connect (Uri.of_string uri) >>=?
  create_tables
  >|= (fun res -> match res with
      | Ok () -> ()
      | Error s -> failwith "this is bad ok"
    )
