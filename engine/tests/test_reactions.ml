open Bacterie_libs
open Local_libs

let logger = Alog.make_logger "Yaac.test_reactions"


let print_bact b =
  logger.debug ~ltags:(lazy [
    "bactery", Bacterie.to_sig_yojson b;
    "reactions", Reac_mgr.to_yojson b.reac_mgr
  ]) ""

let bact_sig_testable =
  Alcotest.testable Bacterie.CompactSig.pp (fun b1 b2 -> compare b1 b2 == 0)

let simple_bind () =
  let bact = Initial_states.simple_bind () in
  logger.debug "start";
  print_bact bact;

  Bacterie.next_reaction bact;

  logger.debug "after 1st reac";
  print_bact bact;

  Bacterie.next_reaction bact;

  logger.debug "after 2nd reac";
  print_bact bact;

  Bacterie.next_reaction bact;

  logger.debug "after 3rd reac";
  print_bact bact;

  let result = Bacterie.to_sig bact
  and expected_result : Bacterie.CompactSig.t =
    Bacterie.CompactSig.canonical
      {
        mols =
          [
            { mol = "BA"; qtt = 1; ambient = false };
            {
              mol = "AAAABAFAFDDFBAAADDFAAAABAFBFDDFBAAADDFAAACBAADDFABB";
              qtt = 1; ambient=false;
            };
          ];
        env = !(bact.env);
      }
  in
  Alcotest.check bact_sig_testable "same bact" expected_result result

and simple_split () =
  let bact = Initial_states.simple_split () in
  Bacterie.next_reaction bact;
  Bacterie.next_reaction bact;

  let result = Bacterie.to_sig bact
  and expected_result : Bacterie.CompactSig.t =
    Bacterie.CompactSig.canonical
      {
        mols =
          [
            { mol = "A"; qtt = 1; ambient=false };
            { mol = "B"; qtt = 1; ambient=false };
            { mol = "AAAABAAFBFDDFBBAADDFAAACAAADDFABBAAACAAADDFABB"; qtt=1; ambient=false};
          ];
        env = !(bact.env);
      }
  in
  Alcotest.check bact_sig_testable "same bact" expected_result result

and simple_break () =
  let bact = Initial_states.simple_break () in
  Bacterie.next_reaction bact;
  Bacterie.next_reaction bact;
  Bacterie.next_reaction bact;

  let result = Bacterie.to_sig bact
  and expected_result =
    Bacterie.CompactSig.canonical
      {
        mols = [ { mol = "A"; qtt = 5; ambient = false } ];
        env = !(bact.env);
      }
  in
  Alcotest.check bact_sig_testable "same bact" expected_result result

and simple_grab_release () =
  let bact = Initial_states.simple_grab_release () in
  logger.info "init ok";
  Bacterie.next_reaction bact;
  logger.info "first reac ok";
  Bacterie.next_reaction bact;

  logger.info "second reac ok";

  let result = Bacterie.to_sig bact
  and expected_result =
    Bacterie.CompactSig.canonical
      {
        mols = [
          { mol = "A"; qtt = 1; ambient = false };
          { mol = "AAABAAADDFABAFAFDDFAAACAAADDFABB"; qtt = 1; ambient=false }
        ];
        env = !(bact.env);
      }
  in

  Alcotest.check bact_sig_testable "same bact" expected_result result

and grab_release_amol () =
  let bact = Initial_states.grab_amol () in
  Bacterie.next_reaction bact;

  let inter_result = Bacterie.to_sig bact
  (* Both mols can grab ? This should probably be changed
     With current setup, the short one grabs the other
  *)
  and inter_expected_result =
    Bacterie.CompactSig.canonical
      {
        mols =
          [
            { mol = "AAAABAFAFAAFFDDFBAAADDFAAACAAADDFABB"; qtt = 1;ambient=false }
            (* {mol="AAAABAFAFDDFBAAADDFAAAABAFBFDDFBAAADDFAAACBAADDFABB";qtt=1}; *);
          ];
        env = !(bact.env);
      }
  in
  Alcotest.check bact_sig_testable "same bact" inter_expected_result
    inter_result;

  Bacterie.next_reaction bact;
  let result = Bacterie.to_sig bact
  and expected_result =
    Bacterie.CompactSig.canonical
      {
        mols =
          [
            {
              mol = "AAAABAFAFDDFBAAADDFAAAABAFBFDDFBAAADDFAAACBAADDFABB";
              qtt = 1; ambient=false
            };
            { mol = "AAAABAFAFAAFFDDFBAAADDFAAACAAADDFABB"; qtt = 1;ambient=false};
          ];
        env = !(bact.env);
      }
  in
  Alcotest.check bact_sig_testable "same bact final" expected_result result

(* and simple_collision () = *)

(*   let bact = Initial_states.simple_collision in *)
(*   Bacterie.next_reaction bact; *)

(*   let result = Bacterie.to_sig bact *)
(*                |> Bacterie.BactSig.canonical *)
(*   and expected_result : Bacterie.bact_sig = *)
(*   Bacterie.BactSig.canonical *)
