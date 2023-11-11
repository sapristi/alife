open Bacterie_libs
open Local_libs
let root_handler =  Jlog.make_handler ~formatter:Jlog.default_formatter ~level:Jlog.Debug ();;
let null_handler =  Jlog.make_handler  ~level:Jlog.NoLevel ();;

Jlog.register_handler "Yaac" root_handler;;
Jlog.register_handler "Yaac.Base_chem" null_handler;;

let () =
  let open Alcotest in
  run "Bacterie tests"
    [
      ( "Full sig - random same behaviour",
        [test_case "same random" `Quick Test_full_sig.test_randstate_same_behaviour;]
      );

      ( "Full Sig initial",
        List.map
          (fun (name, get_bact) ->
            test_case
              ("initial " ^ name)
              `Quick
              (Test_full_sig.test_equality_reacs_before_ser_deser name get_bact 0))
          Initial_states.bacteries );
      ( "Full Sig after 1 reaction",
        List.map
          (fun (name, get_bact) ->
            test_case
              ("1 r " ^ name)
              `Quick
              (Test_full_sig.test_equality_reacs_before_ser_deser name get_bact 1))
          Initial_states.bacteries );
      ( "Full Sig after 10 reaction",
        List.map
          (fun (name, get_bact) ->
            test_case
              ("10 r " ^ name)
              `Quick
              (Test_full_sig.test_equality_reacs_before_ser_deser name get_bact 10))
          Initial_states.bacteries );
      ( "Full Sig, reactions after ser-deser",
        List.map
          (fun (name, get_bact) ->
             test_case
               ("1 r " ^ name)
               `Quick
               (Test_full_sig.test_equality_reacs_after_ser_deser name get_bact 10 10))
          Initial_states.bacteries );
      ( "Reactions rates", [
            test_case "collisions" `Quick Test_reaction_rates.test_collision_reactions_rates;
          ]
      );
      ( "Reactions",
        [
          test_case "simple bind" `Quick Test_reactions.simple_bind;
          test_case "simple split" `Quick Test_reactions.simple_split;
          test_case "simple break" `Quick Test_reactions.simple_break;
          test_case "simple_grab_release" `Quick
            Test_reactions.simple_grab_release;
          test_case "grab_release_amol" `Quick Test_reactions.grab_release_amol;
        ] );
      ( "Run simulation",
        [
          test_case "run many steps" `Quick (Test_run.test_run 100);
          test_case "run custom" `Quick Test_run.test_run_custom;
        ]
      )
    ]
