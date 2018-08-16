open Bacterie_libs;;
open OUnit2;;

let b = ref (Bacterie.make_empty ());;
     

let test1 test_ctx =
  assert_equal (
      
      let bact_json = Yojson.Safe.from_file "bact_states/simple_bind.json" in
      match Bacterie.of_yojson bact_json  with
      | Ok bact ->
         b := bact;
         "ok"
      | Error s -> s) "ok"





               
let env :Environment.t = {transition_rate = 1.;
                          grab_rate = 1.;
                          break_rate = 0.;
                          random_collision_rate = 0.};;



let bact = Bacterie.make_empty ~env:env;;

let suite =
  "suite">:::
    ["test1">::test1]

let () =
  run_test_tt_main suite;;
