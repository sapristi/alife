open Yaac_config

let logger = Easy_logging.Logging.get_logger "Yaac.Libs.Numeric"


(* let logger = Easy_logging.Logging.make_logger "Yaac.Libs.Numeric" Debug [Cli Debug]*)

           
module type NumericT =
  sig

    type num
                 [@@deriving show, ord, yojson]

    val ( + ) : num -> num -> num
    val ( - ) : num -> num -> num
    val ( * ) : num -> num -> num

    val zero : num
    val one : num
    val sqrt : num -> num
    val abs : num -> num
    val num_of_int : int -> num
    val num_of_string : string -> num
      
    val string_of_num : num -> string
    val float_of_num : num -> float
    val random : num -> num

    val lt : num -> num -> bool
    val equal : num -> num -> bool
  end


module Sloppy : NumericT =
  struct
    type num = float
                 [@@deriving show, ord, yojson]
    let ( + ) = ( +. )
    let ( - ) = ( -. )
    let ( * ) = ( *. )
           
    let zero = 0.
    let one = 1.
    let sqrt = Float.sqrt
    let abs = Float.abs
    let num_of_int = float_of_int
    let num_of_string = float_of_string
    let string_of_num = string_of_float
    let float_of_num n = n
    let pp_num f n = Format.pp_print_string f (show_num n)
    let random n = Random.float n
    let lt a b = a < b
    let equal a b = a = b
  end



let rec random_30bit_bits k res =
  let open Z in
  if k = 0 then res
  else
    let res' = (of_int @@ Random.bits ()) + (shift_left res 30) 
    in random_30bit_bits Pervasives.(k-1) res'
         
let rec bigrandom (n : Z.t) : Z.t =
  let open Z in
  let b30 = of_int 30 in
  if numbits n <= 30
  then of_int @@ Random.int @@ to_int n
  else
    let q,r =
      let q',r' = div_rem (of_int (numbits n)) b30 in
      if r' = zero
      then q'- one, b30
      else q', r'
    in
    let m = shift_right n @@ to_int (b30*q) in
    (* shouldn't it be :
       let rbit = of_int @@ Random.int (to_int @@ m + 1) in 
       ????? *)
    
    let rbit = of_int @@ Random.int (to_int m) in
    let rbit' = shift_left rbit @@ to_int (b30*q) in
    if rbit = m
    then
      rbit' + bigrandom (n-rbit')
    else
      rbit' + random_30bit_bits (to_int q) zero



let bigrandom_veryeasy (n: Z.t) : Z.t =
  let open Z in
  let k = numbits n in
  let q,r = div_rem (of_int k) (of_int 30) in
  let q' =
    if r = zero then q else q + one
  in
  let rand =  ref  (random_30bit_bits (to_int q') zero) in
  while !rand > n do
    rand := random_30bit_bits (to_int q') zero
  done;
  !rand

  
module ExactZ : NumericT =
  struct
    include Z
              
    type num = t
             
      
    let string_of_num = to_string
    let num_of_int = of_int

    let compare_num = compare
                   
    let show_num = string_of_num
    let pp_num f n = Format.pp_print_string f (show_num n)

    let num_of_string = of_string
    let float_of_num = to_float 
    let num_to_yojson n =
      `String (string_of_num n)
    let num_of_yojson (json : Yojson.Safe.json) =
      match json with
      | `String s -> Ok (of_string s)
      | `Int n -> Ok (of_int n)
      | `Float f ->
         (
           try
             let n = int_of_float f in
             Ok (of_int n)
           with _  ->
             Error "ExactZ cannot load float"
         )
      | _ -> Error "cannot load json"

    (** [Warning] not overflow safe *)
    let random n =
      bigrandom n

  end
   
module ExactQ : NumericT =
  struct
    include Q
    type num = t
    let ( + ) = Q.add
    let ( - ) = Q.sub
    let ( * ) = Q.mul

    let sqrt {num=n;den=m} =
      {num=Z.sqrt n;den=Z.sqrt m}
    let string_of_num = to_string
    let num_of_int = of_int
    let num_of_string = of_string
    let compare_num = compare
    let show_num = string_of_num
    let pp_num f n = Format.pp_print_string f (show_num n)
                   
    let float_of_num = to_float 
    let num_to_yojson n =
      `String (string_of_num n)
    let num_of_yojson (json : Yojson.Safe.json) =
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

let num = 
  match Config.num with
  | Sloppy -> (module Sloppy : NumericT)
  | ExactZ -> (module ExactZ : NumericT)
  | ExactQ -> (module ExactQ : NumericT)

module Num = (val num : NumericT)
