open Molecule;;
open Proteine;;
open Proteine;;
open Petri_net
open Bacterie;;
open Web_server;;
open Acid_types.AcidTypes;;
open Graber;;
open Atome.Atome;;
open Sandbox;;
  
open Bact_server;;
  

let port = ref 1512;;
let host = ref "localhost";;

let speclist = [ ("-port", Arg.Int (fun x -> port := x), "connection port");
                 ("-host", Arg.String (fun x -> host := x), "declared host; must match the adress provided to the client")]
    in let usage_msg = "Bact simul serveur" 
       in Arg.parse speclist print_endline usage_msg
;;

  
 
let prot2 = [
    Node; Extension Init_with_token_ext; InputArc ("A", Regular_iarc);
    Node ; OutputArc ("A", Regular_oarc);
    Node ; Extension Init_with_token_ext;];;


let prot3 = [
    Node ;
    Extension Init_with_token_ext;
    InputArc ("A", Regular_iarc);
    InputArc ("B", Regular_iarc);
    
    Node ;
    OutputArc ("A", Regular_oarc);

    
    Node ;
    OutputArc ("B", Regular_oarc);

  ];;



let patt_mol = [A;A;A;A;F;A;F;A;A;A;A];;
let graber = Graber.build_from_atom_list patt_mol;;
    
let prot4 = [
    Node ;
    Extension (Grab_ext graber)];;
  
let mol5 = [A;A;A;A;A;A;A;A;A;];;

let print_prot prot = 
  let mol = Proteine.to_molecule prot in
  let str = Molecule.to_string mol in
  print_endline str;
  
    in
    print_prot prot2;
    print_prot prot3;
    print_prot prot4;
    
    
    let make_bact () =
      let bact =Bacterie.empty in
      
      Bacterie.add_proteine prot2 bact;
      Bacterie.add_proteine prot3 bact;
      Bacterie.add_proteine prot4 bact;
      Bacterie.add_molecule mol5 bact;
      bact
    in
    
    start_srv (handle_req (make_bact ()) SandBox.empty) (!host, !port) 
   
