open Bacterie_libs;;
open Reactors;;
open Easy_logging_yojson;;

let () = Printexc.record_backtrace true;;

let rlogger = Logging.make_logger "Yaac" Debug [Cli Debug];;

let logger = Logging.get_logger "Yaac";;
let rlogger = Logging.get_logger "Yaac.Bact.Reacs.reacs_mgr" in
    rlogger#set_level Debug;;

let print_bact b =
  logger#debug "%s" (Yojson.Safe.to_string @@ Bacterie.to_sig_yojson b);
  logger#debug "%s" (Reac_mgr.show b.reac_mgr)
    
let test () =
  let sandbox = Sandbox.of_yojson
      ( Yojson.Safe.from_file "../tests/bact_states/simple_collision.json" ) 
      
  in
  logger#flash "start";
  print_bact !(sandbox.bact);
  
  Bacterie.next_reaction !(sandbox.bact);
  
  logger#flash "after 1st reac";
  print_bact !(sandbox.bact);
  
  Bacterie.next_reaction !(sandbox.bact);
  
  logger#flash "after 2nd reac";
  print_bact !(sandbox.bact);
  
  Bacterie.next_reaction !(sandbox.bact);
  
  logger#flash "after 3rd reac";
  print_bact !(sandbox.bact);;

let () = 
  try
    test ()
  with  | _ as e ->
    logger#error "stack: %s\n%s"
      (Printexc.get_backtrace ())
      (Printexc.to_string e);
