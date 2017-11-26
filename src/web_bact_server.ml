open Molecule;;
open Proteine;;
open Proteine;;
open Petri_net
open Bacterie;;
open Web_server;;
open AcidTypes;;
open Graber;;
open Sandbox;;
  
open Bact_server;;
  

let port = ref 1512;;
let host = ref "localhost";;

  
    
  let speclist = [ ("-port", Arg.Int (fun x -> port := x), "connection port");
                   ("-host", Arg.String (fun x -> host := x), "declared host; must match the adress provided to the client")]
      in let usage_msg = "Bact simul serveur" 
         in Arg.parse speclist print_endline usage_msg
  ;;
    
 

    
    let make_bact () : Bacterie.t =
      
      let bact = Bacterie.make_empty () in
      
      let data_json =  Yojson.Safe.from_file "bact.save" in
      Bacterie.json_reset data_json bact;
      bact
               
      in
      
       start_srv (handle_req (make_bact ()) SandBox.empty) (!host, !port) 
   
