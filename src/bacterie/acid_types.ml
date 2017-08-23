open Graber

(* * defining types for acids *)
(* ** description générale :in_progress: *)
(*    Implémentation des types différents acides. Voilà en gros l'organisation : *)
(*   + place : aucune fonctionalité *)
(*   + transition : agit sur la molécule contenue dans un token *)
(*     - regular : rien de particulier *)
(*     - split : coupe une molécule en 2 (seulement transition_input) *)
(*     - bind : insère une molécule dans une autre (seulement transition_output) *)
(*     - release : supprime le token, et relache l'éventuelle molécule *)
(*       contenue dans celui-ci *)
(*   + extension : autres ? *)
(*     - handle : poignée pour attraper cette molécule *)
(*       problème : il faudrait pouvoir attrapper la molécule à n'importe quel acide ? ou alors on attrappe la poignée directement et pas la place associée *)
(*     - catch : permet d'attraper une molécule. *)
(*       Est ce qu'il y a une condition d'activation, par exemple un token vide (qui contiendrait ensuite la molécule) ? *)
(*     - release : lache la molécule attachée -> plutot dans les transitions *)
(*     - move : déplace le point de contact de la molécule *)
(*     - send : envoie un message *)
(*     - receive : receives a message *)

(*   Questions : est-ce qu'on met l'action move sur les liens ou en *)
(*   extension ? dans les liens c'est plus cohérent, mais dans les *)
(*   extensions ça permet d'en mettre plusiers à la suite. Par contre, à *)
(*   quel moment est-ce qu'on déclenche l'effet de bord ? En recevant le *)
(*   token d'une transition.  Mais du coup pour l'action release, il *)
(*   faudrait aussi la mettre sur les places, puisqu'on agit aussi à *)
(*   l'extérieur du token. Du coup pour l'instant on va mettre à la fois *)
(*   move et release dans les extensions, avec un système pour appliquer *)
(*   les effets des extensions quand on reçoit un token. *)

(*   L'autre question est, comment appliquer les effets de bord qui *)
(*   affectent la bactérie ? *)
(*   Le plus simple est de mettre les actions ayant de tels effets de bord *)
(*   sur les transitions, donc send_message et release_mol seront sur *)
(*   les olink *)
  
(* ** implémentation *)
              
module AcidTypes =
  struct
(* *** place *)
    type place_type = Regular_place
                          [@@deriving show, yojson]
    
(* *** transition_input *)
    type transition_input_type = 
      | Regular_ilink
      | Split_ilink
      | Filter_ilink of string
                          [@@deriving show, yojson]
                      
(* *** transition_output *)
    type transition_output_type = 
      | Regular_olink
      | Bind_olink
      | Release_olink
[@@deriving show, yojson]



(* *** extension *)
(* Types used by the extensions. Usefull to use custom types for easier potential changes later on.  *)
    type handle_id = string
                       [@@deriving show, yojson]
    type bind_pattern = string
                           [@@deriving show, yojson]
    type receive_pattern = string
                             [@@deriving show, yojson]
    type msg_format = string
                        [@@deriving show, yojson]
                    
    type extension_type =
      | Handle_ext of handle_id
      | Catch_ext of bind_pattern
      | Grab_ext of Graber.t
      | Release_ext
      | Displace_mol_ext of bool
      | Init_with_token_ext
      | Information_ext of string
                         [@@deriving show, yojson]
  end;;
