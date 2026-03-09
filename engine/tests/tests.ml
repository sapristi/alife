open Bacterie_libs
open Local_libs
let root_handler =  Jlog.make_handler ~formatter:Jlog.Formatters.default ~level:Jlog.Debug ();;
let null_handler =  Jlog.make_handler  ~level:Jlog.NoLevel ();;

Jlog.register_handler "Yaac" root_handler;;
Jlog.register_handler "Yaac.Base_chem" null_handler;;

let () =
  let open Alcotest in
  run "Bacterie tests"
    [
      ( "Full sig - random same behaviour",
        [test_case "same random" `Quick Test_dump.test_randstate_same_behaviour;]
      );

      ( "Full Sig initial",
        List.map
          (fun (name, get_bact) ->
            test_case
              ("initial " ^ name)
              `Quick
              (Test_dump.test_equality_reacs_before_ser_deser name get_bact 0))
          Initial_states.bacteries );
      ( "Full Sig after 1 reaction",
        List.map
          (fun (name, get_bact) ->
            test_case
              ("1 r " ^ name)
              `Quick
              (Test_dump.test_equality_reacs_before_ser_deser name get_bact 1))
          Initial_states.bacteries );
      ( "Full Sig after 10 reaction",
        List.map
          (fun (name, get_bact) ->
            test_case
              ("10 r " ^ name)
              `Quick
              (Test_dump.test_equality_reacs_before_ser_deser name get_bact 10))
          Initial_states.bacteries );
      ( "Full Sig, reactions after ser-deser",
        List.map
          (fun (name, get_bact) ->
             test_case
               ("1 r " ^ name)
               `Quick
               (Test_dump.test_equality_reacs_after_ser_deser name get_bact 10 10))
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
      );
      ( "Double pop bug",
        [
          test_case "duplicate input arcs from same place" `Quick
            Test_double_pop.test_double_pop_does_not_crash;
        ]
      );
      ( "Self-replication",
        [
          test_case "endless_duplication replicates" `Slow
            Test_replication.test_endless_duplication_replicates;
          test_case "endless_duplication robust" `Slow
            Test_replication.test_endless_duplication_robust;
          test_case "endless_duplication species diversity" `Slow
            Test_replication.test_endless_duplication_species_diversity;
          test_case "ribosome_1 runs reactions" `Slow
            Test_replication.test_ribosome_1_runs_reactions;
          test_case "ribosome_1 assembles molecules" `Slow
            Test_replication.test_ribosome_1_assembles_molecules;
          test_case "endless_duplication deterministic" `Slow
            Test_replication.test_endless_duplication_deterministic;
          test_case "ribosome_1 deterministic" `Slow
            Test_replication.test_ribosome_1_deterministic;
        ]
      )
    ]
