open Easy_logging_yojson
open Lwt.Infix
open Infix
type 'a row_type_abs ={
  name: string;
  description: string;
  ts: Ptime.t;
  data: 'a
}
type connection = (Caqti_lwt.connection, Caqti_error.t) result Lwt.t

module type TABLE_PARAMS = sig
  type data_type

  val table_name: string
  val init_values: (string * string * data_type) list

  val encode_data: data_type -> (string, _) result
  val decode_data: string -> (data_type, string) result
end

module MakeBaseTable (TableParams: TABLE_PARAMS) = struct

  open TableParams
  type row_type = data_type row_type_abs
  let logger = Logging.get_logger [%string "Yaac.Db.%{table_name}"]

  let (>>=?) m f =
    m >>= (function
        | Ok x -> f x
        | Error err -> logger#serror (Caqti_error.show err); Lwt.return (Error err)
      )

  module DataType = struct
    type t = data_type
    let t =
      let encode = encode_data in
      let decode = decode_data in
      let rep = Caqti_type.string in
      Caqti_type.custom ~encode ~decode rep
  end


  let add_one conn (name, description, data) =
  let add_one_req = Caqti_request.exec
      Caqti_type.(tup4 string string ptime DataType.t)
      [%string {| INSERT INTO %{table_name}
                  (name, description, ts, data)
                  VALUES (?, ?, ?, ?) |} ]
  in
  conn >>=? fun (module Conn : Caqti_lwt.CONNECTION) ->
  Conn.exec add_one_req (name, description, Ptime_clock.now (), data)

  let find_opt conn name = 
    let get_opt_req = Caqti_request.find_opt
        Caqti_type.string
        Caqti_type.(tup4 string string ptime DataType.t)
        [%string "SELECT * FROM %{table_name} WHERE name = ?" ]
    in
    conn >>=? fun (module Conn : Caqti_lwt.CONNECTION) ->
    Conn.find_opt get_opt_req name

  let list conn =
    let list_req = Caqti_request.collect
        Caqti_type.unit Caqti_type.(tup3 string string ptime)
        [%string "SELECT name, description, ts FROM %{table_name}" ]
    in
    conn >>=? fun (module Conn : Caqti_lwt.CONNECTION) ->
    Conn.collect_list list_req ()

  let update_req = Caqti_request.exec
      Caqti_type.(tup4 string ptime DataType.t string)
      [%string {|
  UPDATE %{table_name}
        SET description=?, ts=?, data=?
        WHERE name = ?
  |} ]


  let populate_init rows (module Conn : Caqti_lwt.CONNECTION) =
    let populate_init_req = Caqti_request.exec
        Caqti_type.(tup4 string string ptime DataType.t)
        [%string {| INSERT OR IGNORE INTO %{table_name}
                    (name, description, ts, data)
                    VALUES(?, ?, ?, ?)     |}]
    in
    Lwt_list.fold_left_s
      (fun res (name, description, data)-> match res with
         | Ok () -> logger#info "Insert %s" name; Conn.exec populate_init_req (name, description, Ptime_clock.now(), data)
         | Error err -> Error err |> Lwt.return)
      (Ok ()) rows
    >>=? fun _ -> (Ok (module Conn : Caqti_lwt.CONNECTION)) |> Lwt.return


  let setup_table (module Conn : Caqti_lwt.CONNECTION) =
    let create_table_req = Caqti_request.exec Caqti_type.unit
        [%string {eot|
  CREATE TABLE IF NOT EXISTS %{table_name} (
    name TEXT PRIMARY KEY,
    description TEXT NOT NULL,
    ts TIME NOT NULL,
    data TEXT NOT NULL
  ) WITHOUT ROWID
  |eot} ]
    in
    logger#debug "creating table %s" table_name;
    Conn.exec create_table_req ()
    >>=? fun () -> populate_init init_values (module Conn)
end
