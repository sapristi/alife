open Custom_types;;
open MyMolecule;;
open Proteine;;
open Serveur;;

  
let mol2 = [
    Node Regular_place; Extension Init_with_token; TransitionInput ("a", Regular_ilink); Node Regular_place; TransitionOutput ("a", Regular_olink);
    Node Regular_place; Extension Init_with_token;];;

  
let prot2 = Proteine.make mol2;;


go_prot_interface prot2;;
