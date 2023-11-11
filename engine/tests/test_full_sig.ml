open Bacterie_libs
open Local_libs

let logger = Jlog.make_logger "Yaac.Test.full_sig"

let bact_testable = Alcotest.testable Bacterie.pp_full Bacterie.equal
let reac_mgr_testable = Alcotest.testable Reac_mgr.pp Reac_mgr.equal
let reac_mgr_t_testable = Alcotest.testable Reac_mgr.TSet.pp Reac_mgr.TSet.equal
let reac_mgr_g_testable = Alcotest.testable Reac_mgr.GSet.pp Reac_mgr.GSet.equal
let reac_mgr_b_testable = Alcotest.testable Reac_mgr.BSet.pp Reac_mgr.BSet.equal
let reac_mgr_c_testable = Alcotest.testable Reac_mgr.CSet.pp Reac_mgr.CSet.equal

(** Checks that the ser-desered is the same bactery, after the given number of reactions *)
let test_equality_reacs_before_ser_deser name get_bact nb_reacs () =
  let bact = get_bact () in
  for i = 1 to nb_reacs do
    Bacterie.next_reaction bact;
    Reac_mgr.check_reac_rates bact.reac_mgr;
  done;

  (Array.make 30 "SER DESER - ") |> Array.fold_left (fun res value -> value^res) "" |> logger.info;
  let serdeser =
    bact |> Bacterie_libs.Bacterie.FullSig.bact_to_yojson
    |> Bacterie_libs.Bacterie.FullSig.bact_of_yojson |> Result.get_ok
  in
  Alcotest.check reac_mgr_t_testable
    ("reac_mgr t " ^ name)
    bact.reac_mgr.t_set serdeser.reac_mgr.t_set;
  Alcotest.check reac_mgr_g_testable
    ("reac_mgr g " ^ name)
    bact.reac_mgr.g_set serdeser.reac_mgr.g_set;
  Alcotest.check reac_mgr_b_testable
    ("reac_mgr b " ^ name)
    bact.reac_mgr.b_set serdeser.reac_mgr.b_set;
  Alcotest.check reac_mgr_c_testable
    ("reac_mgr c " ^ name)
    bact.reac_mgr.c_set serdeser.reac_mgr.c_set;

  Alcotest.check reac_mgr_testable
    ("reac_mgr " ^ name)
    bact.reac_mgr serdeser.reac_mgr;
  Alcotest.check bact_testable ("bact " ^ name) bact serdeser

(** Checks that the ser-desered is the same bactery, after the given number of reactions *)
let test_equality_reacs_after_ser_deser name get_bact nb_reacs_before nb_reacs_after () =
  let bact = get_bact () in
  for i = 1 to nb_reacs_before do
    Bacterie.next_reaction bact
  done;

  let serdeser =
    bact |> Bacterie_libs.Bacterie.FullSig.bact_to_yojson
    |> Bacterie_libs.Bacterie.FullSig.bact_of_yojson |> Result.get_ok
  in

  for i = 1 to nb_reacs_after do
    Bacterie.next_reaction bact;
    Bacterie.next_reaction serdeser;
    Alcotest.check bact_testable ("bact " ^ name ^ " | step " ^ (string_of_int i)) bact serdeser
  done;

  Alcotest.check bact_testable ("bact " ^ name) bact serdeser


let test_randstate_same_behaviour () =
  let bact = Bacterie.make_empty () in
  let serdeser = bact |> Bacterie_libs.Bacterie.FullSig.bact_to_yojson
    |> Bacterie_libs.Bacterie.FullSig.bact_of_yojson |> Result.get_ok
  in
  for i = 0 to 1000 do
    let res_bact = Random_s.bernouil_f !(bact.randstate) 0.5
    and res_serdeser = Random_s.bernouil_f !(serdeser.randstate) 0.5
    in
    Alcotest.(check bool) ("randstate | step " ^ (string_of_int i)) res_bact res_serdeser
  done
