open Bacterie_libs;;
open OUnit2;;
open Reactors;;

let b = ref (Bacterie.make ());;
     

let test1 test_ctx =
  assert_equal (
      
      let sandbox = Sandbox.of_yojson
                      ( Yojson.Safe.from_file "bact_states/simple_bind.json" ) 
      in
      Bacterie.next_reaction !(sandbox.bact);
      Bacterie.next_reaction !(sandbox.bact);
      Bacterie.next_reaction !(sandbox.bact);
      Bacterie.next_reaction !(sandbox.bact);
      Bacterie.to_sig !(sandbox.bact))
               {active_mols = [{mol="AAAABAFAFDDFBAAADDFAAAABAFBFDDFBAAADDFAAACBAADDFABB";qtt=1}];
                inert_mols = [{mol="AB"; qtt=1; ambient=false}]}
      

let suite =
  "suite">:::
    ["test1">::test1]

let () =
  run_test_tt_main suite;;
