open Yaac_config
open Easy_logging_yojson


module Q =
struct
  let numlogger = Logging.get_logger "Yaac.Libs.Numeric"
  include Q
  let ( + ) = Q.add
  let ( - ) = Q.sub
  let ( * ) = Q.mul

  let sqrt {num=n;den=m}: Q.t =
    let open Z.Compare in 
    if Config.check_sqrt &&  (n < Z.zero || m < Z.zero)
    then
      begin
        numlogger#error "Sqrt of %s / %s"
          (Z.to_string n) (Z.to_string m);
        failwith  "error"
      end;
    {num=Z.sqrt n;den=Z.sqrt m}
  let compare_num = compare
  let show = to_string
  let pp f n = Format.pp_print_string f (show n)

  let float_of_num = to_float
  let to_yojson n =
    `String (to_string n)
  let of_yojson (json : Yojson.Safe.t) =
    numlogger#debug "Num from '%s'" (Yojson.Safe.to_string json);
    match json with
    | `String s -> Ok (of_string s)
    | `Int n -> Ok (of_int n)
    | `Float f -> Ok (of_float f)
    | _ ->
      numlogger#error "Cannot decode num from %s" (Yojson.Safe.to_string json);
      Error "cannot load json "

 end
