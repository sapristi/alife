open Yaac_config
open Easy_logging_yojson


module Q =
  struct
    let logger = Logging.get_logger "Yaac.Libs.Numeric"
    include Q
    let ( + ) = Q.add
    let ( - ) = Q.sub
    let ( * ) = Q.mul
                  
    let sqrt {num=n;den=m} =
      {num=Z.sqrt n;den=Z.sqrt m}
    let compare_num = compare
    let show = to_string
    let pp f n = Format.pp_print_string f (show n)
        
    let float_of_num = to_float 
    let to_yojson n =
      `String (to_string n)
    let of_yojson (json : Yojson.Safe.t) =
      logger#debug "Num from '%s'" (Yojson.Safe.to_string json);
      match json with
      | `String s -> Ok (of_string s)
      | `Int n -> Ok (of_int n)
      | `Float f -> Ok (of_float f)
  | _ ->
    logger#error "Cannot decode num from %s" (Yojson.Safe.to_string json);
    Error "cannot load json " 
           
    (** [Warning] QUICK AND DIRTY
        but this should be ok    *)
    (*let random {num=n; den=m} =
      {num= bigrandom n; den=m} *)
    let random q =
      let r = Random.float 1. in
      q * (of_float r)
  end

