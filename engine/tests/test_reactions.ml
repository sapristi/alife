(* open Bacterie_libs;; *)
(* open OUnit2;; *)
(* open Reactors;; *)
(* open Easy_logging_yojson;; *)

(* let root_logger = Logging.make_logger "Yaac" Debug [Cli Debug];; *)
(* (\*let logger = Logging.make_logger "Yaac" Debug [];;*\) *)

(* let logger = Logging.get_logger "Yaac.test_reactions";; *)

(* let rlogger = Logging.get_logger "Yaac.Bact.Reacs.reacs_mgr" in *)
(*     rlogger#set_level Debug;; *)

(* let print_bact b = *)
(*   logger#debug "%s" (Yojson.Safe.to_string @@ Bacterie.to_sig_yojson b); *)
(*   logger#debug "%s" (Reac_mgr.show b.reac_mgr) *)

(* let simple_bind test_ctx = *)

(*   let sandbox = Sandbox.of_yojson *)
(*       ( Yojson.Safe.from_file "../../data/bact_states/simple_bind.json" ) *)
(*                 |> Result.get_ok *)
(*   in *)
(*   logger#debug "start"; *)
(*   print_bact !(sandbox.bact); *)

(*   Bacterie.next_reaction !(sandbox.bact); *)

(*   logger#debug "after 1st reac"; *)
(*   print_bact !(sandbox.bact); *)

(*   Bacterie.next_reaction !(sandbox.bact); *)

(*   logger#debug "after 2nd reac"; *)
(*   print_bact !(sandbox.bact); *)

(*   Bacterie.next_reaction !(sandbox.bact); *)

(*   logger#debug "after 3rd reac"; *)
(*   print_bact !(sandbox.bact); *)

(*   let result = Bacterie.to_sig !(sandbox.bact) *)
(*                |> Bacterie.canonical_bact_sig *)

(*   and expected_result : Bacterie.bact_sig = *)
(*     Bacterie.canonical_bact_sig *)
(*       {active_mols = [{mol="AAAABAFAFDDFBAAADDFAAAABAFBFDDFBAAADDFAAACBAADDFABB";qtt=1}]; *)
(*        inert_mols = [{mol="BA"; qtt=1; ambient=false}]} *)

(*   in *)

(*   assert_equal *)
(*     ~printer:Bacterie.show_bact_sig *)
(*     expected_result result *)

(* and simple_split test_ctx = *)

(*   let sandbox = Sandbox.of_yojson *)
(*       ( Yojson.Safe.from_file "../../data/bact_states/simple_split.json" ) *)
(*                 |> Result.get_ok *)
(*   in *)
(*   Bacterie.next_reaction !(sandbox.bact); *)
(*   Bacterie.next_reaction !(sandbox.bact); *)

(*   let result = Bacterie.to_sig !(sandbox.bact) *)
(*                |> Bacterie.canonical_bact_sig *)

(*   and expected_result : Bacterie.bact_sig = *)
(*     Bacterie.canonical_bact_sig *)
(*       {active_mols = [{mol="AAAABAAFBFDDFBBAADDFAAACAAADDFABBAAACAAADDFABB";qtt=1}]; *)
(*        inert_mols = [{mol="A"; qtt=1; ambient=false}; {mol="B"; qtt=1; ambient=false}]} *)

(*   in *)

(*   assert_equal *)
(*     ~printer:Bacterie.show_bact_sig *)
(*      expected_result result *)

(* and simple_break test_ctx = *)
(*   let sandbox = Sandbox.of_yojson *)
(*       ( Yojson.Safe.from_file "../../data/bact_states/simple_break.json" ) *)
(*                 |> Result.get_ok *)
(*   in *)
(*   Bacterie.next_reaction !(sandbox.bact); *)
(*   Bacterie.next_reaction !(sandbox.bact); *)
(*   Bacterie.next_reaction !(sandbox.bact); *)

(*   let result = Bacterie.to_sig !(sandbox.bact) *)
(*                |> Bacterie.canonical_bact_sig *)

(*   and expected_result : Bacterie.bact_sig = *)
(*     Bacterie.canonical_bact_sig *)
(*       {active_mols = []; *)
(*        inert_mols = [{mol="A"; qtt=5; ambient=false};]} *)

(*   in *)

(*   assert_equal *)
(*     ~printer:Bacterie.show_bact_sig *)
(*     expected_result result *)

(* and simple_grab_release test_ctx = *)

(*   logger#info "simple grab release"; *)
(*   let sandbox = Sandbox.of_yojson *)
(*       ( Yojson.Safe.from_file "../../data/bact_states/simple_grab_release.json" ) *)
(*                 |> Result.get_ok *)
(*   in *)
(*   logger#info "init ok"; *)
(*   Bacterie.next_reaction !(sandbox.bact); *)
(*   logger#info "first reac ok"; *)
(*   Bacterie.next_reaction !(sandbox.bact); *)

(*   logger#info "second reac ok"; *)

(*   let result = Bacterie.to_sig !(sandbox.bact) *)
(*                |> Bacterie.canonical_bact_sig *)

(*   and expected_result : Bacterie.bact_sig = *)
(*     Bacterie.canonical_bact_sig *)
(*       {active_mols = [ *)
(*          {mol="AAABAAADDFABAFAFDDFAAACAAADDFABB";qtt=1}]; *)
(*        inert_mols = [{mol="A"; qtt=1; ambient=false};]} *)

(*   in *)

(*   assert_equal *)
(*     ~printer:Bacterie.show_bact_sig *)
(*     expected_result result *)

(* let grab_release_amol test_ctx = *)

(*   logger#info "grab release amol"; *)
(*   let sandbox = Sandbox.of_yojson *)
(*       ( Yojson.Safe.from_file "../../data/bact_states/grab_amol.json" ) *)
(*                 |> Result.get_ok *)
(*   in *)
(*   Bacterie.next_reaction !(sandbox.bact); *)

(*   let inter_result = Bacterie.to_sig !(sandbox.bact) *)
(*                |> Bacterie.canonical_bact_sig *)

(*   and inter_expected_result : Bacterie.bact_sig = *)
(*     Bacterie.canonical_bact_sig *)
(*       {active_mols = [ *)
(*          {mol="AAAABAFAFDDFBAAADDFAAAABAFBFDDFBAAADDFAAACBAADDFABB";qtt=1}; *)
(*        ]; *)
(*        inert_mols = []} in *)

(*   assert_equal *)
(*     ~printer:Bacterie.show_bact_sig *)
(*     inter_expected_result inter_result; *)

(*   Bacterie.next_reaction !(sandbox.bact); *)

(*   let result = Bacterie.to_sig !(sandbox.bact) *)
(*                |> Bacterie.canonical_bact_sig *)

(*   and expected_result : Bacterie.bact_sig = *)
(*     Bacterie.canonical_bact_sig *)
(*       {active_mols = [ *)
(*          {mol="AAAABAFAFDDFBAAADDFAAAABAFBFDDFBAAADDFAAACBAADDFABB";qtt=1}; *)
(*          {mol="AAAABAFAFAAFFDDFBAAADDFAAACAAADDFABB";qtt=1} *)
(*        ]; *)
(*        inert_mols = []} in *)

(*   assert_equal *)
(*     ~printer:Bacterie.show_bact_sig *)
(*     expected_result result *)

(* (\* *)
(* and simple_collision test_ctx = *)
(*   let sandbox = Sandbox.of_yojson *)
(*       (Yojson.Safe.from_file "bact_states/simple_collision.json") *)
(*   in Bacterie.next_reaction !(sandbox.bact); *)

(*   let result = Bacterie.to_sig !(sandbox.bact) *)
(*                |> Bacterie.canonical_bact_sig *)
(*   and expected_result : Bacterie.bact_sig = *)
(*     Bacterie.canonical_bact_sig *)
(*   *\) *)

(* let suite = *)
(*   "suite">::: *)
(*     ["simple bind">::simple_bind; *)
(*      "simple split">::simple_split; *)
(*      "simple break">::simple_break; *)
(*      "simple_grab_release">::simple_grab_release; *)
(*     ] *)

(* let () = *)
(*   run_test_tt_main suite;; *)
