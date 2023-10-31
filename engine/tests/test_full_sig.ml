open Bacterie_libs

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
    Bacterie.next_reaction bact
  done;

  let serdeser =
    bact |> Bacterie_libs.Bacterie.FullSig.bact_to_yojson
    |> Bacterie_libs.Bacterie.FullSig.bact_of_yojson |> Result.get_ok
  in
  Reac_mgr.CSet.check_reac_rate bact.reac_mgr.c_set;
  Reac_mgr.CSet.check_reac_rate serdeser.reac_mgr.c_set;
  Alcotest.check reac_mgr_t_testable
    ("ser_deser reac_mgr t " ^ name)
    bact.reac_mgr.t_set serdeser.reac_mgr.t_set;
  Alcotest.check reac_mgr_g_testable
    ("ser_deser reac_mgr g " ^ name)
    bact.reac_mgr.g_set serdeser.reac_mgr.g_set;
  Alcotest.check reac_mgr_b_testable
    ("ser_deser reac_mgr b " ^ name)
    bact.reac_mgr.b_set serdeser.reac_mgr.b_set;
  Alcotest.check reac_mgr_c_testable
    ("ser_deser reac_mgr c " ^ name)
    bact.reac_mgr.c_set serdeser.reac_mgr.c_set;

  Alcotest.check reac_mgr_testable
    ("ser_deser reac_mgr " ^ name)
    bact.reac_mgr serdeser.reac_mgr;
  Alcotest.check bact_testable ("ser_deser bact " ^ name) bact serdeser

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
  done;


  Reac_mgr.CSet.check_reac_rate bact.reac_mgr.c_set;
  Reac_mgr.CSet.check_reac_rate serdeser.reac_mgr.c_set;
  Alcotest.check reac_mgr_t_testable
    ("ser_deser reac_mgr t " ^ name)
    bact.reac_mgr.t_set serdeser.reac_mgr.t_set;
  Alcotest.check reac_mgr_g_testable
    ("ser_deser reac_mgr g " ^ name)
    bact.reac_mgr.g_set serdeser.reac_mgr.g_set;
  Alcotest.check reac_mgr_b_testable
    ("ser_deser reac_mgr b " ^ name)
    bact.reac_mgr.b_set serdeser.reac_mgr.b_set;
  Alcotest.check reac_mgr_c_testable
    ("ser_deser reac_mgr c " ^ name)
    bact.reac_mgr.c_set serdeser.reac_mgr.c_set;

  Alcotest.check reac_mgr_testable
    ("ser_deser reac_mgr " ^ name)
    bact.reac_mgr serdeser.reac_mgr;
  Alcotest.check bact_testable ("ser_deser bact " ^ name) bact serdeser
