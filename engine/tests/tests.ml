open Bacterie_libs

let () = print_endline "I AM A TEST"
let () = print_endline (Sys.getcwd ())

let () =
  let open Alcotest in
  run "Bacterie tests"
    [
      ( "Full Sig initial",
        List.map
          (fun (name, get_bact) ->
            test_case
              ("ser deser initial " ^ name)
              `Quick
              (Test_full_sig.test_equality_reacs_before_ser_deser name get_bact 0))
          Initial_states.bacteries );
      ( "Full Sig after 1 reaction",
        List.map
          (fun (name, get_bact) ->
            test_case
              ("ser deser 1 reaction " ^ name)
              `Quick
              (Test_full_sig.test_equality_reacs_before_ser_deser name get_bact 1))
          Initial_states.bacteries );
      ( "Full Sig after 10 reaction",
        List.map
          (fun (name, get_bact) ->
            test_case
              ("ser deser 10 reaction " ^ name)
              `Quick
              (Test_full_sig.test_equality_reacs_before_ser_deser name get_bact 10))
          Initial_states.bacteries );
      ( "Full Sig, reactions after ser-deser",
        List.map
          (fun (name, get_bact) ->
             test_case
               ("ser deser 1 reaction " ^ name)
               `Quick
               (Test_full_sig.test_equality_reacs_after_ser_deser name get_bact 10 10))
          Initial_states.bacteries );

      ( "Reactions",
        [
          test_case "simple bind" `Quick Test_reactions.simple_bind;
          test_case "simple split" `Quick Test_reactions.simple_split;
          test_case "simple break" `Quick Test_reactions.simple_break;
          test_case "simple_grab_release" `Quick
            Test_reactions.simple_grab_release;
          test_case "grab_release_amol" `Quick Test_reactions.grab_release_amol;
        ] );
    ]
