open Bacterie_libs
open Easy_logging_yojson


let q_testable = Alcotest.testable Q.pp_print Q.equal

let test_collision_reactions_rates () =
  let bact = Bacterie.make_empty () in let env = Environment.make ~break_rate:Q.one () in

  Bacterie.add_molecule "A" bact |> Bacterie.execute_actions bact;
  Alcotest.check q_testable "same rate" Q.zero (Reac_mgr.CSet.total_rate bact.reac_mgr.c_set)
