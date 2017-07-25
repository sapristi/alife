open Custom_types;;
open MyMolecule;;
open Proteine;;
open Serveur;;

let mol2 = [Node Initial_place; Node Regular_place; TransitionInput ("a", Regular_ilink); TransitionOutput ("a", Regular_olink); Node Regular_place];;
  
let prot2 = Proteine.make mol2;;


go_prot_interface prot2;;
