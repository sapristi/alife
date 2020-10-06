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

module DBTime = struct
  include Ptime
  let to_yojson time : Yojson.Safe.t = `Float (Ptime.to_float_s time)
  let of_yojson (json: Yojson.Safe.t) : (Ptime.t, string) result =
    let float_res =
      match json with
      | `Float f -> Ok f
      | `Int i -> Ok (float_of_int i)
      | `String s -> (float_of_string_opt s)
                     |> Option.to_result
                       ~none:(Format.sprintf "string repr is not a number: %s" s)
    in
    Result.bind float_res
      (fun f ->
         Ptime.of_float_s f
         |> Option.to_result ~none:(Format.sprintf "Cannot convert to date: %f" f)
      )
end


module type TABLE_PARAMS = sig
  type data_type

  val table_name: string

  val data_type_to_yojson: data_type -> Yojson.Safe.t
  val data_type_of_yojson: Yojson.Safe.t -> (data_type, string) result
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
    [@@deriving yojson]
    let t =
      let encode = fun x -> Ok (Yojson.Safe.to_string (data_type_to_yojson x)) in
      let decode = fun x -> data_type_of_yojson (Yojson.Safe.from_string x) in
      let rep = Caqti_type.string in
      Caqti_type.custom ~encode ~decode rep
  end

  module FullType = struct
    type t = {name: string; description: string; ts: DBTime.t; data: DataType.t}
    [@@deriving yojson]

    type dump = t list
    [@@deriving yojson]

    let t =
      let encode {name; description; ts; data} =
        Ok (name, description, ts, data) in
      let decode (name, description, ts, data) =
        Ok {name; description; ts; data = data} in
      let rep = Caqti_type.(tup4 string string ptime DataType.t) in
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

  let delete_one conn name =
    let delete_one_req = Caqti_request.exec
        Caqti_type.(string)
        [%string {| DELETE from  %{table_name} where
                  name = ? |} ]
    in
    conn >>=? fun (module Conn : Caqti_lwt.CONNECTION) ->
    Conn.exec delete_one_req name

  let find_opt conn name = 
    let get_opt_req = Caqti_request.find_opt
        Caqti_type.string
        Caqti_type.(tup4 string string ptime DataType.t)
        [%string "SELECT * FROM %{table_name} WHERE name = ?" ]
    in
    conn >>=? fun (module Conn : Caqti_lwt.CONNECTION) ->
    Conn.find_opt get_opt_req name

  let find_res conn name =
    find_opt conn name
    >|=! Option.to_result ~none:("Cannot find "^name)

  let list conn =
    let list_req = Caqti_request.collect
        Caqti_type.unit Caqti_type.(tup3 string string ptime)
        [%string "SELECT name, description, ts FROM %{table_name}" ]
    in
    conn >>=? fun (module Conn : Caqti_lwt.CONNECTION) ->
    Conn.collect_list list_req ()

  let dump conn = 
    let dump_req = Caqti_request.collect
        Caqti_type.unit FullType.t
        [%string "SELECT * FROM %{table_name}" ]
    in
    conn >>=? fun (module Conn : Caqti_lwt.CONNECTION) ->
    Conn.collect_list dump_req ()

  let load_dump (module Conn : Caqti_lwt.CONNECTION) dump =
    let populate_init_req = Caqti_request.exec
        FullType.t
        [%string {| INSERT OR IGNORE INTO %{table_name}
                    (name, description, ts, data)
                    VALUES(?, ?, ?, ?)     |}]
    in
    Lwt_list.fold_left_s
      (fun res item-> match res with
         | Ok () -> Conn.exec populate_init_req item
         | Error err -> Error err |> Lwt.return)
      (Ok ()) dump
    >>=? fun _ -> (Ok (module Conn : Caqti_lwt.CONNECTION)) |> Lwt.return

  let load_dump_file conn dump_file =
    logger#info "Loading file %s" dump_file;
    Yojson.Safe.from_file dump_file
    |> FullType.dump_of_yojson
    |> (function | Ok ok -> logger#info "load ok %s" dump_file; ok
                 | Error r -> logger#error "load ko %s" r; failwith "this is bad")
    |> load_dump conn

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


  module RequestHandler = struct

    open Opium.Std

    type partial_item = {name: string; description: string; time: string}
    [@@deriving yojson]

    (* type post_item = (string * string * data_type)
     * [@@deriving yojson] *)

    let list db_conn req =
      list db_conn
      >|=! List.map (fun (name, description, time) ->
          partial_item_to_yojson {name; description; time=Ptime.to_rfc3339 time})
      >|= fun data -> `Json (`List data)

    let dump db_conn req =
      dump db_conn
      >|=! List.map FullType.to_yojson
      >|= fun l -> `Json (`List l)


    let delete db_conn (req: Request.t) =
      let name = param req "name"
      in delete_one db_conn name

    (* let add db_conn (req: Opium.Std.Request.t) =
     *   req.body
     *   |> Cohttp_lwt.Body.to_string
     *   >|= Yojson.Safe.from_string
     *   >|= post_item_of_yojson
     *   >|= Result.get_ok
     *   >>= (fun sig_post -> (
     *         (add_one db_conn sig_post)
     *         >|= Result.get_ok
     *       ))
     *   >|= (fun () -> `Empty) *)

  end

end
