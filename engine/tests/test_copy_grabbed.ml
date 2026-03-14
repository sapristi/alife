open Bacterie_libs
open Reactants_maps

let count_areactants bact =
  let json = ARMap.stats bact.Bacterie.areactants in
  match json with
  | `Assoc l ->
    (match List.assoc "total_nb" l with `Int n -> n | _ -> 0)
  | _ -> 0

let count_ireactant_species bact =
  let json = IRMap.stats bact.Bacterie.ireactants in
  match json with
  | `Assoc l ->
    (match List.assoc "total_nb" l with `Int n -> n | _ -> 0)
  | _ -> 0

let run_reactions n bact =
  for _ = 1 to n do
    ignore (Bacterie.next_reaction bact)
  done

let test_copy_grabbed_replicates () =
  (* GIVEN a T-copier copy_grabbed system (copies templates exactly, including DAEEE) *)
  let bact = Initial_states.copy_grabbed_copier () in

  (* initial: 1 active copier, 10 templates + 6 ambient acids = 16+ inert *)
  let initial_inert = count_ireactant_species bact in

  (* WHEN we run 500 reactions (1 copy cycle ≈ 76 reactions) *)
  run_reactions 500 bact;

  (* THEN templates should have increased (T-copier produces inert copies) *)
  let final_inert = count_ireactant_species bact in
  Alcotest.(check bool)
    (Printf.sprintf
       "inert molecules should increase (initial=%d, final=%d)"
       initial_inert final_inert)
    true (final_inert > initial_inert)

let test_copy_grabbed_robust () =
  (* GIVEN a T-copier copy_grabbed system *)
  let bact = Initial_states.copy_grabbed_copier () in

  (* WHEN we run 2000 reactions *)
  run_reactions 2000 bact;

  (* THEN the copier should survive (still 1 active molecule) *)
  let final_active = count_areactants bact in
  Alcotest.(check bool)
    (Printf.sprintf "copier should survive (active=%d)" final_active)
    true (final_active >= 1)
