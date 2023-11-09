(* (* open Yaac_config *) *)

module Q = struct
  let numlogger = Alog.make_logger "Yaac.Libs.Numeric"

  include Q

  let to_yojson n = `String (to_string n)

  let ( + ) = Q.add
  let ( - ) = Q.sub
  let ( * ) = Q.mul

  let sqrt input : Q.t =
    let { num = n; den = m } = input in
    let open Z.Compare in
    if Config.check_sqrt && (n < Z.zero || m < Z.zero) then (
      numlogger.error ~tags:["num", to_yojson input]"sqrt issue ?";
      failwith "error");
    { num = Z.sqrt n; den = Z.sqrt m }

  let compare_num = compare
  let show = to_string
  let pp f n = Format.pp_print_string f (show n)
  let float_of_num = to_float

  let of_yojson (json : Yojson.Safe.t) =
    numlogger.debug ~tags:["input", json] "Converting Num from";
    match json with
    | `String s -> Ok (of_string s)
    | `Int n -> Ok (of_int n)
    | `Float f -> Ok (of_float f)
    | _ ->
      numlogger.error ~tags:["input", json] "Cannot decode num";
        Error "cannot load json "
end
