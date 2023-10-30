open Bacterie_libs;;
open Easy_logging_yojson;;

let root_logger = Logging.make_logger "Yaac" Debug [Cli Debug];;

let logger = Logging.get_logger "Yaac.test_reactions";;

let rlogger = Logging.get_logger "Yaac.Bact.Reacs.reacs_mgr" in
    rlogger#set_level Debug;;

let print_bact b =
  logger#debug "%s" (Yojson.Safe.to_string @@ Bacterie.to_sig_yojson b);
  logger#debug "%s" (Reac_mgr.show b.reac_mgr)


let bact_sig_testable = Alcotest.testable Bacterie.BactSig.pp (fun b1 b2 -> compare b1 b2 == 0)


let simple_bind () =
  let bact = Initial_states.simple_bind in
  (
    logger#debug "start";
    print_bact bact;

    Bacterie.next_reaction bact;

    logger#debug "after 1st reac";
    print_bact bact;

    Bacterie.next_reaction bact;

    logger#debug "after 2nd reac";
    print_bact bact;

    Bacterie.next_reaction bact;

    logger#debug "after 3rd reac";
    print_bact bact;

    let result = Bacterie.to_sig bact

    and expected_result : Bacterie.BactSig.t =
      Bacterie.BactSig.canonical
        {active_mols = [{mol="AAAABAFAFDDFBAAADDFAAAABAFBFDDFBAAADDFAAACBAADDFABB";qtt=1}];
         inert_mols = [{mol="BA"; qtt=1; ambient=false}];
         env = !(bact.env);
        }
    in
    Alcotest.check bact_sig_testable "same bact" expected_result result
  )




and simple_split () =

  let bact = Initial_states.simple_split in
  Bacterie.next_reaction bact;
  Bacterie.next_reaction bact;

  let result = Bacterie.to_sig bact

  and expected_result : Bacterie.BactSig.t =
    Bacterie.BactSig.canonical
      {active_mols = [{mol="AAAABAAFBFDDFBBAADDFAAACAAADDFABBAAACAAADDFABB";qtt=1}];
       inert_mols = [{mol="A"; qtt=1; ambient=false}; {mol="B"; qtt=1; ambient=false}];
       env = !(bact.env);
      }
  in
  Alcotest.check bact_sig_testable "same bact" expected_result result




and simple_break () =

  let bact = Initial_states.simple_break in
  Bacterie.next_reaction bact;
  Bacterie.next_reaction bact;
  Bacterie.next_reaction bact;

  let result = Bacterie.to_sig bact
               |> Bacterie.BactSig.canonical

  and expected_result  =
    Bacterie.BactSig.canonical
      {active_mols = [];
       inert_mols = [{mol="A"; qtt=5; ambient=false};];
       env = !(bact.env);
      }
  in
  Alcotest.check bact_sig_testable "same bact" expected_result result




and simple_grab_release () =

  let bact = Initial_states.simple_grab_release in
  logger#info "init ok";
  Bacterie.next_reaction bact;
  logger#info "first reac ok";
  Bacterie.next_reaction bact;

  logger#info "second reac ok";

  let result = Bacterie.to_sig bact
               |> Bacterie.BactSig.canonical

  and expected_result =
    Bacterie.BactSig.canonical
      {active_mols = [
          {mol="AAABAAADDFABAFAFDDFAAACAAADDFABB";qtt=1}];
       inert_mols = [{mol="A"; qtt=1; ambient=false};];
       env = !(bact.env);
      }

  in
  Alcotest.check bact_sig_testable "same bact" expected_result result



and grab_release_amol () =

  let bact = Initial_states.grab_amol in
  Bacterie.next_reaction bact;

  let inter_result = Bacterie.to_sig bact
                     |> Bacterie.BactSig.canonical

  (* Both mols can grab ? This should probably be changed
     With current setup, the short one grabs the other
  *)
  and inter_expected_result =
    Bacterie.BactSig.canonical
      {active_mols = [
          {mol="AAAABAFAFAAFFDDFBAAADDFAAACAAADDFABB";qtt=1}
          (* {mol="AAAABAFAFDDFBAAADDFAAAABAFBFDDFBAAADDFAAACBAADDFABB";qtt=1}; *)
        ];
       inert_mols = [];
       env = !(bact.env);
      } in
  Alcotest.check bact_sig_testable "same bact" inter_expected_result inter_result;

  Bacterie.next_reaction bact;
  let result = Bacterie.to_sig bact
               |> Bacterie.BactSig.canonical

  and expected_result =
    Bacterie.BactSig.canonical
      {active_mols = [
          {mol="AAAABAFAFDDFBAAADDFAAAABAFBFDDFBAAADDFAAACBAADDFABB";qtt=1};
          {mol="AAAABAFAFAAFFDDFBAAADDFAAACAAADDFABB";qtt=1}
        ];
       inert_mols = [];
       env = !(bact.env);
      } in
  Alcotest.check bact_sig_testable "same bact final" expected_result result

(* and simple_collision () = *)

(*   let bact = Initial_states.simple_collision in *)
(*   Bacterie.next_reaction bact; *)

(*   let result = Bacterie.to_sig bact *)
(*                |> Bacterie.BactSig.canonical *)
(*   and expected_result : Bacterie.bact_sig = *)
(*   Bacterie.BactSig.canonical *)

