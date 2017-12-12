

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

(* *** place *)
type place_type = Regular_place
                    [@@deriving yojson]
                
(* *** transition_input *)
type input_arc = 
  | Regular_iarc
  | Split_iarc
  | Filter_iarc of string
  | Filter_empty_iarc
[@@deriving yojson]
  
(* *** transition_output *)
type output_arc = 
  | Regular_oarc
  | Merge_oarc
  | Move_oarc of bool
                   [@@deriving  yojson]


(* *** extension *)
(* Types used by the extensions. Usefull to use custom types for easier potential changes later on.  *)
type handle_id = string
                   [@@deriving  yojson]
type bind_pattern = string
                      [@@deriving  yojson]
type receive_pattern = string
                         [@@deriving  yojson]
type msg_format = string
                    [@@deriving  yojson]
                
type extension =
  | Grab_ext of string
  | Release_ext
  | Init_with_token_ext
  | Bind_ext of string
          
[@@deriving  yojson]
  
(*      
      | Information of string  
      | Displace_mol of bool
      | Handle of handle_id   
      | Catch of bind_pattern *)


  
(* ** type definitions *)
(* *** acid type definition *)
(*     We define how the abstract types get combined to form functional  *)
(*     types to eventually create petri net *)
(*       + Node : used as a token placeholder in the petri net *)
(*       + TransitionInput :  an incomming edge into a transition of the  *)
(*       petri net *)
(*       + a transition output : an outgoing edge into a transition of the  *)
(*       petri net *)
(*       + a piece of information : ???? *)
  
type acid = 
  | Place
  | InputArc of string * input_arc
  | OutputArc of string * output_arc
  | Extension of extension
                   [@@deriving yojson]

          
(* * AcidExamples module *)
  
module Examples = 
  struct
    let nodes = [ Place;]
    let input_arcs = [
        InputArc ("A", Regular_iarc);
        InputArc ("A", Split_iarc);
        InputArc ("A", Filter_iarc "A");
        InputArc ("A", Filter_empty_iarc);]
    let output_arcs = [
        OutputArc ("A", Regular_oarc);
        OutputArc ("A", Merge_oarc);
        OutputArc ("A", Move_oarc true);]
    let extensions = [
        Extension (Release_ext);
        Extension (Init_with_token_ext);
        Extension (Grab_ext "AAFBFAAFF");
        Extension (Bind_ext "AA");
      ]

  end;;
