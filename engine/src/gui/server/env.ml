
let db_key : ((Caqti_lwt.connection, Caqti_error.t) result Lwt.t) Opium.Context.key = Opium.Context.Key.create ("db pool" , fun _ ->  Sexplib.Std.sexp_of_string "db_pool")

let add_env_middleware key value name=
  let filter handler (req : Opium.Request.t) =
    let env = Opium.Context.add key value req.env in
    handler {req with env} in
  Rock.Middleware.create ~name:name ~filter


