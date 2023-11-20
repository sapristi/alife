open Bacterie_libs
open Local_libs

let test_run n_steps () =

  let bact = Initial_states.grab_amol () in

  for i = 1 to n_steps do
    Bacterie.next_reaction bact;
    Reac_mgr.check_reac_rates bact.reac_mgr;
  done;
  Alcotest.check Alcotest.bool "run without exception" true true

(** long run of complex situation *)
let test_run_custom () =

  let bact = Initial_states.endless_duplication () in

  for i = 1 to 1000 do
    Bacterie.next_reaction bact;
    Reac_mgr.check_reac_rates bact.reac_mgr;
  done;
  let serdeser = bact |> Bacterie_libs.Bacterie.Dump.bact_to_yojson
                 |> Bacterie_libs.Bacterie.Dump.bact_of_yojson |> Result.get_ok
  in
  for i = 1 to 1000 do
    Bacterie.next_reaction serdeser;
    Reac_mgr.check_reac_rates bact.reac_mgr;
  done;

  Alcotest.check Alcotest.bool "run without exception" true true
