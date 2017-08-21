open Molecule.Molecule;;
open Molecule.AcidTypes;;
open Proteine;;

open Bacterie;;
open Bact_simul_serveur;;
  
let mol2 = [
    Node Regular_place; Extension Init_with_token; TransitionInput ("a", Regular_ilink); Node Regular_place; TransitionOutput ("a", Regular_olink);
    Node Regular_place; Extension Init_with_token;];;

  
let prot2 = Proteine.make mol2;;


let mol3 = [
    Node Regular_place;
    Extension Init_with_token;
    TransitionInput ("a", Regular_ilink);
    TransitionInput ("b", Regular_ilink);
    
    Node Regular_place;
    TransitionOutput ("a", Regular_olink);

    
    Node Regular_place;
    TransitionOutput ("b", Regular_olink);

  ];;

let bact = Bacterie.empty;;
  
  Bacterie.add_molecule mol2 bact;;
    Bacterie.add_molecule mol3 bact;;
  
go_bact_interface bact;;
