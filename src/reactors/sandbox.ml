
open Bacterie_libs

type t = Bacterie.t ref

  

let json_reset json_data sandbox : unit =
  match Bacterie.of_yojson json_data with
  | Ok bact -> sandbox := bact
  | Error s -> failwith  s

let make_default () =
  let sandbox = ref (Bacterie.make_empty ()) in
  let data_json =  Yojson.Safe.from_file "bact.save" in
  json_reset data_json sandbox;
  sandbox
