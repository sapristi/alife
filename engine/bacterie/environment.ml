open Local_libs.Numeric

type t = {
  mutable transition_rate : Q.t;[@default Q.zero]
  mutable grab_rate : Q.t;[@default Q.zero]
  mutable break_rate : Q.t;[@default Q.zero]
  mutable collision_rate : Q.t; [@default Q.zero]
}
[@@deriving show, yojson, eq, make]

let (null_env : t) =
  {
    transition_rate = Q.zero;
    grab_rate = Q.zero;
    break_rate = Q.zero;
    collision_rate = Q.zero;
  }

