open Bacterie_libs
open Easy_logging_yojson

let test_run n_steps () =

  let bact = Initial_states.grab_amol () in

  for i = 1 to n_steps do
    Bacterie.next_reaction bact;
    Reac_mgr.check_reac_rates bact.reac_mgr;
  done;
  Alcotest.check Alcotest.bool "run without exception" true true

(** reproduces bug found in experiments*)
let test_run_custom () =

  let bact = Initial_states.grab_amol () in

  for i = 1 to 100 do
    Bacterie.next_reaction bact;
    Reac_mgr.check_reac_rates bact.reac_mgr;
  done;
  let serdeser = bact |> Bacterie_libs.Bacterie.FullSig.bact_to_yojson
                 |> Bacterie_libs.Bacterie.FullSig.bact_of_yojson |> Result.get_ok
  in
  for i = 1 to 100 do
    Bacterie.next_reaction serdeser;
    Reac_mgr.check_reac_rates bact.reac_mgr;
  done;

  Alcotest.check Alcotest.bool "run without exception" true true
