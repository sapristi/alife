


type t = {
    mutable transition_rate : float;
    mutable grab_rate : float;
    mutable break_rate : float;
    mutable random_collision_rate:float
  }
           [@@ deriving yojson]       
