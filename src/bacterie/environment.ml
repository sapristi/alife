open Local_libs.Numeric


type t = {
    mutable transition_rate : Num.num;
    mutable grab_rate : Num.num;
    mutable break_rate : Num.num;
    mutable collision_rate:Num.num
  }
           [@@ deriving show, yojson]       

       (*
let (default_env : t) =
  {transition_rate = 10.;
   grab_rate = 1.;
   break_rate = 0.0000001;
   collision_rate = 0.0000001}
        *)
