
open Molecule.Molecule;;
open Acid_types.AcidTypes;;
open Proteine.Proteine;;
open Mol_simul_serveur;;
open Petri_net
  
let prot2 = [
    Node Regular_place; Extension Init_with_token_ext; TransitionInput ("a", Regular_ilink); Node Regular_place; TransitionOutput ("a", Regular_olink);
    Node Regular_place; Extension Init_with_token_ext;];;

  
let pnet2 = PetriNet.make_from_prot prot2;;


let prot3 = [
    Node Regular_place;
    Extension Init_with_token_ext;
    TransitionInput ("a", Regular_ilink);
    TransitionInput ("b", Regular_ilink);
    
    Node Regular_place;
    TransitionOutput ("a", Regular_olink);

    
    Node Regular_place;
    TransitionOutput ("b", Regular_olink);

  ];;

let pnet3 = PetriNet.make_from_prot prot3;;
  
go_prot_interface pnet2;;

 
