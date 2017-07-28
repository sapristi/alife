open Custom_types;;
open MyMolecule;;
open Proteine;;
open Serveur;;

  
let mol2 = [Node Regular_place; TransitionInput ("a", Regular_ilink); Node Regular_place; TransitionOutput ("a", Regular_olink); Node Regular_place];;

  
let prot2 = Proteine.make mol2;;


go_prot_interface prot2;;
