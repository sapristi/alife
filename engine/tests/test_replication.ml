open Bacterie_libs
open Reactants_maps

let count_areactants bact =
  let json = ARMap.stats bact.Bacterie.areactants in
  match json with
  | `Assoc l ->
    (match List.assoc "total_nb" l with `Int n -> n | _ -> 0)
  | _ -> 0

let count_areactant_species bact =
  let json = ARMap.stats bact.Bacterie.areactants in
  match json with
  | `Assoc l ->
    (match List.assoc "nb_species" l with `Int n -> n | _ -> 0)
  | _ -> 0

let count_ireactants bact =
  let json = IRMap.stats bact.Bacterie.ireactants in
  match json with
  | `Assoc l ->
    (match List.assoc "total_nb" l with `Int n -> n | _ -> 0)
  | _ -> 0

let run_reactions n bact =
  for _ = 1 to n do
    ignore (Bacterie.next_reaction bact);
    Reac_mgr.check_reac_rates bact.reac_mgr
  done

let test_endless_duplication_replicates () =
  (* GIVEN an endless_duplication system with its initial active molecules *)
  let bact = Initial_states.endless_duplication () in
  let initial_active = count_areactants bact in

  (* WHEN we run 2000 reactions *)
  run_reactions 2000 bact;

  (* THEN the number of active molecules should have increased *)
  let final_active = count_areactants bact in
  Alcotest.(check bool)
    (Printf.sprintf
       "active molecules should increase (initial=%d, final=%d)"
       initial_active final_active)
    true (final_active > initial_active)

let test_endless_duplication_robust () =
  (* GIVEN an endless_duplication system with its initial active molecules *)
  let bact = Initial_states.endless_duplication () in
  let initial_active = count_areactants bact in

  (* WHEN we run 5000 reactions *)
  run_reactions 5000 bact;

  (* THEN the active molecule count should at least double *)
  let final_active = count_areactants bact in
  Alcotest.(check bool)
    (Printf.sprintf
       "active molecules should at least double (initial=%d, final=%d)"
       initial_active final_active)
    true (final_active >= initial_active * 2)

let test_endless_duplication_species_diversity () =
  (* GIVEN an endless_duplication system with its initial active species *)
  let bact = Initial_states.endless_duplication () in
  let initial_species = count_areactant_species bact in

  (* WHEN we run 2000 reactions *)
  run_reactions 2000 bact;

  (* THEN new distinct active species should have appeared *)
  let final_species = count_areactant_species bact in
  Alcotest.(check bool)
    (Printf.sprintf
       "active species should diversify (initial=%d, final=%d)"
       initial_species final_species)
    true (final_species > initial_species)

let test_ribosome_1_runs_reactions () =
  (* GIVEN a ribosome_1 system with exactly 1 active molecule *)
  let bact = Initial_states.ribosome_1 () in
  let initial_active = count_areactants bact in
  Alcotest.(check int) "starts with 1 active molecule" 1 initial_active;

  (* WHEN we run 500 reactions *)
  run_reactions 500 bact;

  (* THEN the ribosome should have performed over 100 meaningful reactions *)
  let reac_count = bact.reac_mgr.reac_counter in
  Alcotest.(check bool)
    (Printf.sprintf "should perform many reactions (counter=%d)" reac_count)
    true (reac_count > 100)

let test_ribosome_1_assembles_molecules () =
  (* GIVEN a ribosome_1 system with its initial inert molecule pool *)
  let bact = Initial_states.ribosome_1 () in
  let initial_inert = count_ireactants bact in

  (* WHEN we run 500 reactions *)
  run_reactions 500 bact;

  (* THEN the ribosome should have assembled new inert molecules from ambient material *)
  let final_inert = count_ireactants bact in
  Alcotest.(check bool)
    (Printf.sprintf
       "inert molecule count should increase (initial=%d, final=%d)"
       initial_inert final_inert)
    true (final_inert > initial_inert)

(* Deterministic tests: collision_rate=0 removes the only source of
   randomness beyond the seeded PRNG, making results fully reproducible. *)

let load_deterministic name =
  let bact = (Bacterie.CompactSig.of_yojson
    (Yojson.Safe.from_file ("./bact_states/" ^ name ^ ".json"))
    |> Base.Result.ok_or_failwith |> Bacterie.CompactSig.to_bact) in
  let env = !(bact.Bacterie.env) in
  env.collision_rate <- Local_libs.Numeric.Q.zero;
  env.break_rate <- Local_libs.Numeric.Q.zero;
  bact

let test_endless_duplication_deterministic () =
  (* GIVEN an endless_duplication system with collision and break rates set to 0 *)
  let bact = load_deterministic "endless_duplication" in

  (* WHEN we run exactly 10 reactions *)
  run_reactions 10 bact;

  (* THEN we expect exact deterministic counts *)
  Alcotest.(check int) "areactants" 2 (count_areactants bact);
  Alcotest.(check int) "species" 2 (count_areactant_species bact);
  Alcotest.(check int) "ireactants" 250 (count_ireactants bact);
  Alcotest.(check int) "reac_counter" 6 bact.reac_mgr.reac_counter

let test_ribosome_1_deterministic () =
  (* GIVEN a ribosome_1 system with collision and break rates set to 0 *)
  let bact = load_deterministic "ribosome_1" in

  (* WHEN we run exactly 10 reactions *)
  run_reactions 10 bact;

  (* THEN we expect exact deterministic counts *)
  Alcotest.(check int) "areactants" 1 (count_areactants bact);
  Alcotest.(check int) "species" 1 (count_areactant_species bact);
  Alcotest.(check int) "ireactants" 251 (count_ireactants bact);
  Alcotest.(check int) "reac_counter" 6 bact.reac_mgr.reac_counter
