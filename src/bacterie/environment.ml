


type t = {
    mutable transition_rate : float;
    mutable grab_rate : float;
    mutable break_rate : float;
    mutable random_collision_rate:float
  }
           [@@ deriving show, yojson]       

let (default_env : t) =
  {transition_rate = 10.;
   grab_rate = 1.;
   break_rate = 0.0000001;
   random_collision_rate = 0.0000001}
