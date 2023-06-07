
let add_prefix prefix routes =
  List.map
    (fun (meth, route, callback) ->
       meth, (prefix^route), callback)
    routes

module Resp = struct
  let error_to_response e =
    `String (`Assoc ["error", `String e]
             |> Yojson.Safe.to_string)

  let json_to_response j =
    `String (j |> Yojson.Safe.to_string)

  let default_header = Cohttp.Header.of_list []
  let json_h = Cohttp.Header.add default_header "Content-Type" "application/json"
  let respond_error = Opium.Response.of_json  ~status:`Bad_request

  let rec handle r =
    match r with
    | `Empty ->  "" |> Opium.Response.of_plain_text ~status:`No_content
    | `String s -> s |> Opium.Response.of_plain_text
    | `Json (j : Yojson.Safe.t ) -> j |> json_to_response  |>  Opium.Response.of_json
    | `Error (s : string ) -> s |> error_to_response  |> respond_error
    | `Db_res (res: (Yojson.Safe.t, Caqti_error.t) result) ->
      (
        match res with
        | Ok j -> handle (`Json j)
        | Error err -> handle (`Error ("Db error: "^(Caqti_error.show err)))
      )
    | `Res res -> match res with
      | Ok res' -> handle res'
      | Error err -> handle (`Error err)
end

