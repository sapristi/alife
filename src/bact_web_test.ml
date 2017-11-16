open Molecule;;
open Proteine;;
open AcidTypes;;
open Petri_net
open Bacterie;;
open Web_server;;
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
    
 
    let prot2 = [
        Place; Extension Init_with_token_ext;
        InputArc ("A", Regular_iarc);
        Place;
        OutputArc ("A", Regular_oarc);
        Place;
        Extension Init_with_token_ext;];;
    
let prot3 = [
    Place;
    Extension Init_with_token_ext;
    InputArc ("A", Regular_iarc);
    InputArc ("B", Regular_iarc);
    
    Place;
    OutputArc ("A", Regular_oarc);

    
    Place;
    OutputArc ("B", Regular_oarc);

  ];;



      print_endline ("abc");;
    
let prot4 = [
    Place;
    Extension (Grab_ext (Graber.make [A;A;A;A;F;A;F;A;A;A;A]))
  ];;

let mol5 = [Atome.A;A;A;A;A;A;A;A;A];;


      let print_prot prot = 
        let mol = Proteine.to_molecule prot in
        print_endline (Molecule.to_string mol);
  
    in
    
    
    let make_bact () =
      
      let bact =Bacterie.empty in
      print_prot prot2;
      Bacterie.add_proteine prot2 bact;
      print_prot prot3;
      Bacterie.add_proteine prot3 bact;
      print_prot prot4;
      Bacterie.add_proteine prot4 bact;
      Bacterie.add_molecule mol5 bact;
      bact
    in
    
    print_endline ("abc");
    start_srv (handle_req (make_bact ()) SandBox.empty) (!host, !port) 
   
