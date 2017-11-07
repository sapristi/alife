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
  
open Bact_new_server;;
  

 
 
let prot2 = [
    Node Regular_place; Extension Init_with_token_ext; TransitionInput ("A", Regular_ilink);
    Node Regular_place; TransitionOutput ("A", Regular_olink);
    Node Regular_place; Extension Init_with_token_ext;];;


let prot3 = [
    Node Regular_place;
    Extension Init_with_token_ext;
    TransitionInput ("A", Regular_ilink);
    TransitionInput ("B", Regular_ilink);
    
    Node Regular_place;
    TransitionOutput ("A", Regular_olink);

    
    Node Regular_place;
    TransitionOutput ("B", Regular_olink);

  ];;



let patt_mol = [A;A;A;A;D;A;D;A;A;A;A];;
let graber = Graber.build_from_atom_list patt_mol;;
    
let prot4 = [
    Node Regular_place;
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
    
    start_srv (handle_req (make_bact ()) SandBox.empty) 1512 
   
