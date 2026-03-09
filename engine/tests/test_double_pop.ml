open Bacterie_libs
open Local_libs

(** Test that a molecule with duplicate input arcs from the same place
    does not crash the engine.

    The molecule AAAABCBAAADDFBAAADDFAAACAAADDF creates:
    - Place P0 with init token
    - Transition "A" with TWO Regular_iarc from P0 (duplicate)
    - Place P1 with Regular_oarc from transition "A"

    The launchable check passes (P0 has a token), but apply_input_arcs
    tries to pop P0 twice — the second pop crashes with
    "place.ml : cannot pop No_token".

    This can happen in practice when collisions recombine molecule
    fragments, creating duplicate arc definitions for the same
    transition and place. *)

let double_pop_mol = "AAAABCBAAADDFBAAADDFAAACAAADDF"

let test_double_pop_does_not_crash () =
  let bact = Initial_states.load "double_pop" in
  (* This should not raise an exception *)
  Bacterie.next_reaction bact;
  Alcotest.check Alcotest.bool "transition fires without crash" true true
