open Opium.Std

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
  let respond_error = respond ~headers:json_h ~code:`Bad_request

  let rec handle r =
    match r with
    | `Empty -> `String "" |> respond ~code:`No_content
    | `String s -> `String s |> respond
    | `Json (j : Yojson.Safe.t ) -> j |> json_to_response  |>  respond ~headers:json_h
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
