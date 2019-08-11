open Local_libs.Numeric


type t = {
    mutable transition_rate : Q.t;
    mutable grab_rate : Q.t;
    mutable break_rate : Q.t;
    mutable collision_rate:Q.t
  }
           [@@ deriving show, yojson]       

       (*
let (default_env : t) =
  {transition_rate = 10.;
   grab_rate = 1.;
   break_rate = 0.0000001;
   collision_rate = 0.0000001}
        *)
