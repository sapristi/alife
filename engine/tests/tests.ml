open Bacterie_libs

let () = print_endline "I AM A TEST"
let () = print_endline (Sys.getcwd())

let () =
  let open Alcotest in
  run "Bacterie tests" [
    "Full Sig", [
      test_case "ser deser" `Quick Test_full_sig.ser_deser;
    ];
    "Reactions", [
      test_case "simple bind" `Quick Test_reactions.simple_bind;
      test_case "simple split" `Quick Test_reactions.simple_split;
      test_case "simple break" `Quick Test_reactions.simple_break;
      test_case "simple_grab_release" `Quick Test_reactions.simple_grab_release;
      test_case "grab_release_amol" `Quick Test_reactions.grab_release_amol;
    ]
  ]

