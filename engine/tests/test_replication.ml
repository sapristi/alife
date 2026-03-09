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

  (* WHEN we run 10000 reactions *)
  run_reactions 10000 bact;

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

  (* WHEN we run 10000 reactions *)
  run_reactions 10000 bact;

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

let deterministic_seed : Local_libs.Random_s.t = {
  seed = 42L;
  gamma = 1L;
}

let load_deterministic name =
  let bact = (Bacterie.CompactSig.of_yojson
    (Yojson.Safe.from_file ("./bact_states/" ^ name ^ ".json"))
    |> Base.Result.ok_or_failwith |> Bacterie.CompactSig.to_bact) in
  bact.Bacterie.randstate := deterministic_seed;
  !(bact.Bacterie.env).collision_rate <- Local_libs.Numeric.Q.zero;
  bact

let test_endless_duplication_deterministic () =
  (* GIVEN an endless_duplication system with collision_rate set to 0 and a fixed random seed *)
  let bact = load_deterministic "endless_duplication" in

  (* WHEN we run exactly 100 reactions *)
  run_reactions 100 bact;

  (* THEN we expect exact deterministic molecule counts *)
  let sig_ = Bacterie.to_sig bact in
  let expected : (string * int) list = [
    ("A", 50); ("B", 50); ("C", 50); ("D", 50); ("F", 50);
    ("AAABAAAADDFCBAAADDFBAAABDDFCBAABDDFBAAACDDFCBAACDDFBAAADDDFCBAADDDFBAAAFDDFCBAAFDDFBAAAAADDFCAABBBDDFAAABAAAADDFABAFAFDDFAAABAAABDDFABAFBFDDFAAABAAACDDFABAFCFDDFAAABAAADDDFABAFDFDDFAAABAAAFDDFABAFFFDDFAAABCAAADDFCCAAADDFBCBABDDFCCAABDDFBCCACDDFCCAACDDFBCDADDDFCCAADDDFBCFAFDDFCCAAFDDFBABAAADDFCAABBBDDFAAACAAAAADDFABBAAACAAAAADDFABBAAABAABBBDDFCAACCCDDFAAABAABBBDDFABADFDFFFDDFAAABBACCCDDFCAACCCDDFABC", 1);
  ] in
  List.iter (fun (mol, expected_qtt) ->
    let actual_qtt =
      match List.find_opt (fun (m : Bacterie.CompactSig.mol_sig) -> m.mol = mol) sig_.mols with
      | Some m -> m.qtt
      | None -> 0
    in
    Alcotest.(check int) (Printf.sprintf "mol %s" (String.sub mol 0 (min 30 (String.length mol)))) expected_qtt actual_qtt
  ) expected;
  Alcotest.(check int) "total species" (List.length expected) (List.length sig_.mols)

let test_ribosome_1_deterministic () =
  (* GIVEN a ribosome_1 system with collision_rate set to 0 and a fixed random seed *)
  let bact = load_deterministic "ribosome_1" in

  (* WHEN we run exactly 100 reactions *)
  run_reactions 100 bact;

  (* THEN we expect exact deterministic molecule counts *)
  let sig_ = Bacterie.to_sig bact in
  let expected : (string * int) list = [
    ("A", 50); ("B", 50); ("C", 50); ("D", 50); ("F", 50);
    ("AAABAAAADDFCBAAADDFBAAABDDFCBAABDDFBAAACDDFCBAACDDFBAAADDDFCBAADDDFBAAAFDDFCBAAFDDFBAAAAADDFCAABBBDDFAAABAAAADDFABAFAFDDFAAABAAABDDFABAFBFDDFAAABAAACDDFABAFCFDDFAAABAAADDDFABAFDFDDFAAABAAAFDDFABAFFFDDFAAABCAAADDFCCAAADDFBCBABDDFCCAABDDFBCCACDDFCCAACDDFBCDADDDFCCAADDDFBCFAFDDFCCAAFDDFBABAAADDFCAABBBDDFAAACAAAAADDFABBAAACAAAAADDFABBAAABAABBBDDFCAACCCDDFAAABAABBBDDFABADFDFFFDDFAAABBACCCDDFCAACCCDDFABC", 1);
  ] in
  List.iter (fun (mol, expected_qtt) ->
    let actual_qtt =
      match List.find_opt (fun (m : Bacterie.CompactSig.mol_sig) -> m.mol = mol) sig_.mols with
      | Some m -> m.qtt
      | None -> 0
    in
    Alcotest.(check int) (Printf.sprintf "mol %s" (String.sub mol 0 (min 30 (String.length mol)))) expected_qtt actual_qtt
  ) expected;
  Alcotest.(check int) "total species" (List.length expected) (List.length sig_.mols)
