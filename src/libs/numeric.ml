open Yaac_config

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
      
    val string_of_num : num -> string
    val float_of_num : num -> float
    val random : num -> num
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
    let string_of_num = string_of_float
    let float_of_num n = n
    let pp_num f n = Format.pp_print_string f (show_num n)
    let random n = Random.float n
  end

let qsqrt q =
  let two_q = Q.of_int 2 in
  let rec qsqrt_aux xk n =
    let xk' =
      Q.div
        (Q.add xk (Q.div n xk))
        two_q
      
    in if Q.abs (Q.sub xk xk') < Q.one
       then xk
       else qsqrt_aux xk' n
  in qsqrt_aux q q
   
module ExactZ : NumericT =
  struct
    include Z
              
    type num = t
             
    let ( +$ ) = Z.add
    let ( -$ ) = Z.sub
    let ( *$ ) = Z.mul


    let sqrt n =
      Q.to_bigint @@ qsqrt (Q.of_bigint n)
      
    let string_of_num = to_string
    let num_of_int = of_int

    let compare_num = compare
                   
    let show_num = string_of_num
    let pp_num f n = Format.pp_print_string f (show_num n)

    let float_of_num = to_float 
    let num_to_yojson n =
      `String (string_of_num n)
    let num_of_yojson json =
      match json with
      | `String s -> Ok (of_string s)
      | _ -> Error "cannot load json"

    (** [Warning] not overflow safe *)
    let random n =
      let n' = to_int64 n in
      of_int64 (Random.int64 n')
  end
   
module ExactQ : NumericT =
  struct
    include Q
    type num = t
    let ( + ) = Q.add
    let ( - ) = Q.sub
    let ( * ) = Q.mul

    let sqrt = qsqrt
    let string_of_num = to_string
    let num_of_int = of_int

    let compare_num = compare
    let show_num = string_of_num
    let pp_num f n = Format.pp_print_string f (show_num n)
                   
    let float_of_num = to_float 
    let num_to_yojson n =
      `String (string_of_num n)
    let num_of_yojson json =
      match json with
      | `String s -> Ok (of_string s)
      | _ -> Error "cannot load json"

    (** [Warning] QUICK AND DIRTY
        but this should be ok 
     *)
    let random {num=n; den=m} =
      
      let n' = Z.to_int64 n in
      let rn = Z.of_int64 (Random.int64 n')
      in {num= rn; den= m}
  end

let num = 
  match Config.num with
  | Sloppy -> (module Sloppy : NumericT)
  | ExactZ -> (module ExactZ : NumericT)
  | ExactQ -> (module ExactQ : NumericT)

module Num = (val num : NumericT)
