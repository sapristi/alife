open Local_libs.Numeric


type t = {
  mutable transition_rate : Q.t;
  mutable grab_rate : Q.t;
  mutable break_rate : Q.t;
  mutable collision_rate:Q.t
}
[@@ deriving show, yojson]

let (null_env : t) =
  {transition_rate = Q.zero;
   grab_rate = Q.zero;
   break_rate = Q.zero;
   collision_rate = Q.zero}
