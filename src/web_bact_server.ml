
  
let port = ref 1512;;
let host = ref "localhost";;

  
    
  let speclist = [ ("-port", Arg.Int (fun x -> port := x), "connection port");
                   ("-host", Arg.String (fun x -> host := x), "declared host; must match the adress provided to the client")]
      in let usage_msg = "Bact simul serveur" 
         in Arg.parse speclist print_endline usage_msg
  ;;
    
 

    Logs.set_reporter (Logs_fmt.reporter ());
    Logs.set_level (Some Logs.Info);
    
    let make_bact () : Bacterie.t =
      
      let bact = Bacterie.make_empty () in
      
      let data_json =  Yojson.Safe.from_file "bact.save" in
      Bacterie.json_reset data_json bact;
      bact
               
      in
      
       Web_server.start_srv (Bact_server.handle_req (make_bact ())) (!host, !port) 
   
