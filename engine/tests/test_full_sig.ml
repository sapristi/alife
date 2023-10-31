
open Bacterie_libs

let bact_testable = Alcotest.testable Bacterie.pp Bacterie.equal

let ser_deser () =
  let serdeser = Initial_states.simple_bind
                 |> Bacterie_libs.Bacterie.FullSig.bact_to_yojson
                 |> Bacterie_libs.Bacterie.FullSig.bact_of_yojson
                 |> Result.get_ok
  in
  Alcotest.check bact_testable "same bact"  Initial_states.simple_bind  serdeser

