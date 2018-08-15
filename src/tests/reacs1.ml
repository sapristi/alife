open Bacterie_libs;;

let bact_json = Yojson.Safe.from_file "bact_states/simple_bind.json" in
    match Bacterie.of_yojson bact_json  with
    | Ok bact -> "ok"
    | Error s -> s
    
let env :Environment.t = {transition_rate = 1.;
                          grab_rate = 1.;
                          break_rate = 0.;
                          random_collision_rate = 0.};;



let bact = Bacterie.make_empty ~env:env;

print_endline (
