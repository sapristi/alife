open Bacterie_libs;;
open OUnit2;;
open Reactors;;

let b = ref (Bacterie.make ());;
     

let simple_bind test_ctx =
  
  let sandbox = Sandbox.of_yojson
                  ( Yojson.Safe.from_file "bact_states/simple_bind.json" ) 
  in
  Bacterie.next_reaction !(sandbox.bact);
  Bacterie.next_reaction !(sandbox.bact);
  Bacterie.next_reaction !(sandbox.bact);
  
  let result = Bacterie.to_sig !(sandbox.bact)
               |> Bacterie.canonical_bact_sig 
             
  and expected_result : Bacterie.bact_sig =
    Bacterie.canonical_bact_sig
      {active_mols = [{mol="AAAABAFAFDDFBAAADDFAAAABAFBFDDFBAAADDFAAACBAADDFABB";qtt=1}];
       inert_mols = [{mol="BA"; qtt=1; ambient=false}]}
    
  in

  assert_equal
    ~printer:Bacterie.show_bact_sig 
    expected_result result
  
and simple_split test_ctx =
  
  let sandbox = Sandbox.of_yojson
                  ( Yojson.Safe.from_file "bact_states/simple_split.json" ) 
  in
  Bacterie.next_reaction !(sandbox.bact);
  Bacterie.next_reaction !(sandbox.bact);
  
  let result = Bacterie.to_sig !(sandbox.bact)
               |> Bacterie.canonical_bact_sig 
             
  and expected_result : Bacterie.bact_sig =
    Bacterie.canonical_bact_sig
      {active_mols = [{mol="AAAABAAFBFDDFBBAADDFAAACAAADDFABBAAACAAADDFABB";qtt=1}];
       inert_mols = [{mol="A"; qtt=1; ambient=false}; {mol="B"; qtt=1; ambient=false}]}
    
  in
  
  assert_equal
    ~printer:Bacterie.show_bact_sig 
     expected_result result

and simple_break test_ctx =
  let sandbox = Sandbox.of_yojson
                  ( Yojson.Safe.from_file "bact_states/simple_break.json" ) 
  in 
  Bacterie.next_reaction !(sandbox.bact);


  
  let result = Bacterie.to_sig !(sandbox.bact)
               |> Bacterie.canonical_bact_sig 
             
  and expected_result : Bacterie.bact_sig =
    Bacterie.canonical_bact_sig
      {active_mols = [];
       inert_mols = [{mol="A"; qtt=5; ambient=false};]}
    
  in
  
  assert_equal
    ~printer:Bacterie.show_bact_sig 
    expected_result result

and simple_grab_release test_ctx =
  
  let sandbox = Sandbox.of_yojson
                  ( Yojson.Safe.from_file "bact_states/simple_grab_release.json" ) 
  in 
  Bacterie.next_reaction !(sandbox.bact);
  Bacterie.next_reaction !(sandbox.bact);


  
  let result = Bacterie.to_sig !(sandbox.bact)
               |> Bacterie.canonical_bact_sig 
             
  and expected_result : Bacterie.bact_sig =
    Bacterie.canonical_bact_sig
      {active_mols = [
         {mol="AAABAAADDFABAFAFDDFAAACAAADDFABB";qtt=1}];
       inert_mols = [{mol="A"; qtt=1; ambient=false};]}
    
  in
  
  assert_equal
    ~printer:Bacterie.show_bact_sig 
    expected_result result
  
let suite =
  "suite">:::
    ["simple bind">::simple_bind;
     "simple split">::simple_split;
     "simple break">::simple_break;
     "simple_grab_release">::simple_grab_release;
    ]
  
let () =
  run_test_tt_main suite;;
