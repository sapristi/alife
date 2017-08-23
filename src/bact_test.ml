open Molecule;;
open Proteine;;
open Proteine;;
open Petri_net
open Bacterie;;
open Bact_simul_serveur;;
open Acid_types.AcidTypes
  

let prot2 = [
    Node Regular_place; Extension Init_with_token_ext; TransitionInput ("A", Regular_ilink); Node Regular_place; TransitionOutput ("A", Regular_olink);
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

let print_prot prot = 
  let mol = Proteine.to_molecule prot in
    let str = Molecule.to_string mol in
    print_endline str;;

  print_prot prot2;;
    print_prot prot3;;

  
let bact = Bacterie.empty;;
  
  Bacterie.add_proteine prot2 bact;;
    Bacterie.add_proteine prot3 bact;;
      
go_bact_interface bact;;
