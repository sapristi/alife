
open Reactors
open Bacterie_libs

  

let pnet_ids_from_mol  (sandbox : Sandbox.t) (cgi:Netcgi.cgi) =
  let mol = cgi # argument_value "mol_desc" in
  let pnet_ids = Reactants.ARMap.get_pnet_ids mol !(sandbox.bact).areactants in
  let pnet_ids_json =
    `List (List.map (fun i -> `Int i) pnet_ids)
  in
  `Assoc
   ["purpose", `String "pnet_ids";
    "data", pnet_ids_json]
  |> Yojson.Safe.to_string
  
  
let pnet_from_mol (sandbox : Sandbox.t) (cgi:Netcgi.cgi) =
  let mol = cgi # argument_value "mol_desc"
  and pnet_id = int_of_string (cgi# argument_value "pnet_id") in
  let pnet_json =
    Reactants.ARMap.find_pnet mol pnet_id !(sandbox.bact).areactants
    |> Petri_net.to_json
  in
  `Assoc
   ["purpose", `String "pnet_from_mol";
    "data",  `Assoc ["pnet", pnet_json]] 
  |>  Yojson.Safe.to_string
  
  
let get_bact_elements (sandbox : Sandbox.t) (cgi : Netcgi.cgi) =
  `Assoc
   ["purpose", `String "bact_elements";
    "data", (Bacterie.to_sig_yojson !(sandbox.bact))]
  |> Yojson.Safe.to_string 
  
let get_sandbox_data (sandbox : Sandbox.t) (cgi : Netcgi.cgi) =
 `Assoc
   ["purpose", `String "sandbox_data";
    "data", (Sandbox.to_yojson sandbox)]
  |> Yojson.Safe.to_string 

  
let next_reactions (sandbox : Sandbox.t) (cgi:Netcgi.cgi) =
  let n = cgi # argument_value "n"
          |> int_of_string
  in
  for i = 0 to n-1 do
    Bacterie.next_reaction !(sandbox.bact);
  done;
  `Assoc
   ["purpose", `String "bactery_update_desc";
    "data", (Bacterie.to_sig_yojson !(sandbox.bact))]
  |> Yojson.Safe.to_string 
  
  
let commit_token_edit (sandbox : Sandbox.t) (cgi : Netcgi.cgi)
    : string =
  let token_json = cgi # argument_value "token"
                   |> Yojson.Safe.from_string
  in

  match (Token.option_t_of_yojson token_json) with
  | Ok token_o ->
     (
       let mol = cgi # argument_value "molecule" in
       let pnet_id = int_of_string (cgi # argument_value "pnet_id") in
       let place_index = cgi # argument_value "place_index" 
                         |> int_of_string
       in
       
       let pnet = Reactants.ARMap.find_pnet mol pnet_id !(sandbox.bact).areactants in
       (
         match token_o with
         | Some token -> 
            Place.set_token token pnet.places.(place_index);
         | None -> Place.remove_token pnet.places.(place_index);
       );
       Petri_net.update_launchables pnet;
       
       let pnet_json = Petri_net.to_json pnet in
       `Assoc
        ["purpose", `String "pnet_update";
         "data",  `Assoc ["pnet", pnet_json]]   
       |> Yojson.Safe.to_string
       
     );
  | Error s -> print_endline "error decoding token";
               s
               
               
let launch_transition (sandbox : Sandbox.t) (cgi : Netcgi.cgi) =
  let mol = cgi # argument_value "molecule" 
  and pnet_id = int_of_string (cgi # argument_value "pnet_id") 
  and trans_index = cgi # argument_value "transition_index"
                    |> int_of_string in

  let pnet = Reactants.ARMap.find_pnet mol pnet_id !(sandbox.bact).areactants in
  
  Petri_net.launch_transition_by_id trans_index pnet;
  Petri_net.update_launchables pnet;
  
  let pnet_json = Petri_net.to_json pnet
  in
  `Assoc
   ["purpose", `String "pnet_update";
    "data",  `Assoc ["pnet", pnet_json]]  
  |> Yojson.Safe.to_string 
  
let add_mol (sandbox : Sandbox.t) (cgi : Netcgi.cgi) : string= 
  let mol = cgi # argument_value "mol_desc" in
  Bacterie.add_molecule mol !(sandbox.bact)
  |> Bacterie.execute_actions !(sandbox.bact);
  get_bact_elements sandbox cgi
  
let remove_mol (sandbox : Sandbox.t) (cgi : Netcgi.cgi) = 
  let mol = cgi # argument_value "mol_desc" in
  Reactants.IRMap.remove_all mol !(sandbox.bact).ireactants
  |> Bacterie.execute_actions !(sandbox.bact);
  get_bact_elements sandbox cgi

let set_mol_quantity (sandbox : Sandbox.t) (cgi : Netcgi.cgi) = 
  let mol = cgi # argument_value "mol_desc"
  and n = cgi # argument_value "mol_quantity"
          |> int_of_string
  in
  Reactants.IRMap.set_qtt  n mol !(sandbox.bact).ireactants
  |> Bacterie.execute_actions !(sandbox.bact);
  get_bact_elements sandbox cgi
  
(*
  and save_state bact =
    let data_json = Bacterie.to_json bact in
    Yojson.Safe.to_file "bact.json" data_json;
    "state saved"
 *)
let reset_state (sandbox : Sandbox.t) (cgi : Netcgi.cgi) : string=
  let data_json =  Yojson.Safe.from_file "bact.json" in
  let new_sandbox = Sandbox.of_yojson data_json in
  sandbox.bact := !(new_sandbox.bact);
  sandbox.env := !(new_sandbox.env);
  get_bact_elements sandbox cgi

let set_state (sandbox : Sandbox.t) (cgi : Netcgi.cgi) =
  let new_sandbox = cgi # argument_value "sandbox_desc" 
                    |> Yojson.Safe.from_string
                    |> Sandbox.of_yojson 
  in
  sandbox.bact := !(new_sandbox.bact);
  sandbox.env := !(new_sandbox.env);
  get_sandbox_data sandbox cgi

let set_environment (sandbox : Sandbox.t) (cgi : Netcgi.cgi) =
  (* make something clean of this later on *)

  let tr = cgi # argument_value "env[transition_rate]"
         |> float_of_string
  and gr = cgi # argument_value "env[grab_rate]"
         |> float_of_string
  and br = cgi # argument_value "env[break_rate]"
           |> float_of_string

  in
  let new_env : Environment.t = {transition_rate =tr;
                                 grab_rate=gr;
                                 break_rate=br;random_collision_rate=0.}
  in
  sandbox.env := new_env;
  (* match cgi # argument_value "env"
   *       |> Yojson.Safe.from_string 
   *       |> Environment.of_yojson
   * with
   * | Ok env -> 
   *    !sandbox.env := env;
   *    "done"
   * | Error s ->
   *    "error decoding env from json " ^ s *)
  
  "tesqt sqdqsd"
  
let server_functions =
  [
    "pnet_ids_from_mol", pnet_ids_from_mol;
    "pnet_from_mol" , pnet_from_mol;
    "get_elements", get_bact_elements;
    "get_sandbox_data",  get_sandbox_data; 
    "next_reactions", next_reactions;
    "commit token edit", commit_token_edit;
    "launch_transition",launch_transition;
    "add_mol",add_mol;
    "remove_mol", remove_mol;
    "set_mol_quantity", set_mol_quantity;
    "reset_sandbox", reset_state;
    "set_sandbox",set_state;
    "set_environment", set_environment
  ]
    
   
