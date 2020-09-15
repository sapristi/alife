open Opium.Std

let db_key : ((Caqti_lwt.connection, Caqti_error.t) result Lwt.t) Opium.Hmap.key = Opium.Hmap.Key.create ("db pool" , fun _ ->  Sexplib.Std.sexp_of_string "db_pool")

let add_env_middleware key value name=
  let filter handler (req : Request.t) =
    let env = Opium.Hmap.add key value (Request.env req) in
    handler {req with env} in
  Rock.Middleware.create ~name:name ~filter


