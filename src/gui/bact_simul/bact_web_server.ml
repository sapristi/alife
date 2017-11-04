open Bacterie 


   
let handle_req env (cgi:Netcgi.cgi) bact =

  let gibinitdata () =
    let json_data = `Assoc
                     ["target", `String "main";
                      "purpose", `String "bactery_init_desc";
                      "data", (Bacterie.to_json bact)] in
    
    Yojson.Safe.to_string json_data

  in
  
  
  let command = cgi # argument_value "command" in

  let response = 
  
    if command = "gibinitdata"
    then gibinitdata ()
    else "false"
  in
  cgi # output # output_string response;
  cgi # output # commit_work()
;;
