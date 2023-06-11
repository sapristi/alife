open Easy_logging_yojson
open Lwt.Infix
open Infix
let logger = Logging.get_logger "Yaac.Db.SimTable"

type connection = (Caqti_lwt.connection, Caqti_error.t) result Lwt.t

let (>>=?) m f =
  m >>= (function
      | Ok x -> f x
      | Error err ->  Lwt.return (Error err)
    )


let setup_tables (module Conn : Caqti_lwt.CONNECTION) =
  let create_simtable_req = Caqti_request.exec Caqti_type.unit
      {eot|
  CREATE TABLE IF NOT EXISTS simulation (
    name TEXT PRIMARY KEY,
    description TEXT NOT NULL,
    ts TIME NOT NULL,
    initial_state TEXT,
  ) WITHOUT ROWID
  |eot}
  and create_simdatatable_req = Caqti_request.exec Caqti_type.unit
      {eot|
  CREATE TABLE IF NOT EXISTS simulation_data (
    simulation TEXT,
    bact_index INTEGER,
    step INTEGER,
    ts TIME NOT NULL,
    data TEXT,
  )
  FOREIGN KEY(simulation) REFERENCES simulation(name)
  |eot}
  and create_indexes_req = Caqti_request.exec Caqti_type.unit
      {eot|
      CREATE INDEX IF NOT EXISTS sim_data_sim_index on simulation_data(simulation);
      CREATE INDEX IF NOT EXISTS sim_data_bact on simulation_data(bact_index);
      CREATE INDEX IF NOT EXISTS sim_data_step on simulation_data(step);
      |eot}
  in
  Conn.exec create_simtable_req ()
  >>=? fun _ -> Conn.exec create_simdatatable_req ()
  >>=? fun _ -> Conn.exec create_indexes_req ()


module InitialStateType = struct
  type t = Reactors.Sandbox.signature
  [@@deriving yojson]
  let t =
    let encode = fun x -> Ok (Yojson.Safe.to_string (to_yojson x)) in
    let decode = fun x -> of_yojson (Yojson.Safe.from_string x) in
    let rep = Caqti_type.string in
    Caqti_type.custom ~encode ~decode rep
end

module DataPointType = InitialStateType

let insert conn (name, description, initial_state) =
  let insert_req = Caqti_request.exec
      Caqti_type.(tup4 string string ptime InitialStateType.t)
      {| INSERT INTO simulation
                  (name, description, ts, initial_state)
                  VALUES (?, ?, ?, ?)
|}
  in
  conn >>=? fun (module Conn : Caqti_lwt.CONNECTION) ->
  Conn.exec insert_req (name, description, Ptime_clock.now (), initial_state)


let delete conn name =
  let delete_one_req = Caqti_request.exec
      Caqti_type.(string)
      {| DELETE from simulation where
                  name = ? |}

  and delete_data_req = Caqti_request.exec
      Caqti_type.(string)
      {| DELETE from simulation_data where
                  simulation = ? |}

  in
  conn
  >>=?
  fun (module Conn : Caqti_lwt.CONNECTION) ->
  Conn.exec delete_data_req name
  >>=? fun _ -> Conn.exec delete_one_req name


let add_data conn (name, bact_index, step, data) =
  let insert_req = Caqti_request.exec
      Caqti_type.(tup4 string int int (tup2 DataPointType.t ptime))
      {| INSERT INTO simulation_data
                  (simulation, bact_index, step, data, ts)
                  VALUES (?, ?, ?, ?, ?)
     |}
  in
  conn >>=? fun (module Conn : Caqti_lwt.CONNECTION) ->
  Conn.exec insert_req (name, bact_index, step,  (data, Ptime_clock.now ()))
