open Bacterie_libs;;
open Reactors;;
open Easy_logging_yojson;;
open OUnit2;;
open Containers;;

(* Printexc.record_backtrace true;; *)

(* CCFormat.set_max_indent 50;; *)

(* Random.init 102104;; *)
(* let rlogger = Logging.make_logger "Yaac" Debug [Cli Debug];; *)

(* let logger = Logging.get_logger "Yaac.collision";; *)
(* let rlogger = Logging.get_logger "Yaac.Bact.Reacs.reacs_mgr" in *)
(*     rlogger#set_level Debug;; *)

    
(* let test1 mol1 mol2 = *)
(*   let mol1 = "ACABC" and mol2 = "DEFAB" in *)
(*   let res = Reactions_effects.collide mol1 mol2 in *)

(*   logger#sinfo (Format.sprintf "%a" (List.pp Format.string) res) *)
    

  
(* let () =  *)
(*   try *)
(*     test1 "ACABC"  "DEFAB" ; *)
(*     test1 "A"  "D" ; *)
(*     test1 "AIAJZA"  "ACABCSLDK" ; *)
(*   with  | _ as e -> *)
(*     logger#error "stack: %s\n%s" *)
(*       (Printexc.get_backtrace ()) *)
(*       (Printexc.to_string e); *)

