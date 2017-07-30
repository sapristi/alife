
open Molecule.Molecule
open Molecule
open Token
   
(* * the place module *)


(*    Module qui gère les places. Une place a un type, et peut contenir un jeton.  *)

module Place =
  struct

(* ** divers *)

    type token_holder = EmptyHolder | OccupiedHolder of Token.t
      [@@deriving show]

    let token_holder_to_json (th : token_holder) : Yojson.Safe.json =
      match th with
      | EmptyHolder -> `String "no token"
      | OccupiedHolder t -> Token.to_json t

    type place_exts = AcidTypes.extension_type list;;
    type t =
      {mutable tokenHolder : token_holder;
       placeType : AcidTypes.place_type;
       extensions : AcidTypes.extension_type list}
        [@@deriving show]
(* **** make a place *)
(* ***** DONE allow place extension to initialise the place with an empty token *)

    let make (place_with_exts : AcidTypes.place_type *  place_exts)
        : t =
      let placeType, extensions = place_with_exts in
      if List.mem AcidTypes.Init_with_token extensions
      then
        {tokenHolder = OccupiedHolder Token.empty; placeType;extensions}
      else
        {tokenHolder = EmptyHolder; placeType;extensions}
      
    let is_empty (p : t) : bool =
      p.tokenHolder = EmptyHolder
      
    let remove_token (p : t) : unit=
      p.tokenHolder <- EmptyHolder
      
    let set_token (token : Token.t) (p : t) : unit =
      p.tokenHolder <- OccupiedHolder token
      
  

(* ** Token reçu d'une transition. :deprecated:  *)
(*     Il faut appliquer les effets de bord suivant le type de place. on va écrire une autre fonction qui traite les extensions *)
    
(*
let add_token_from_transition_deprecated (inputToken : Token.t) (p : t) : return_action=
  if is_empty p
  then 
    match p.placeType with
      
    (* il faut dire à l'host qu'on a  relaché la molecule attachée au token.
       est ce qu'on vire aussi le token ??? *)   

    | Release_place ->
       (
         match inputToken with
         | Token.Empty -> set_token Token.empty p; NoAction
         | Token.MolHolder m -> set_token Token.empty p; AddMol m
       );
         
         
    (* il faut faire broadcaster le message par l'host *)
    | Send_place s ->
       begin
         set_token inputToken p;
         SendMessage s
       end
    (* il faut déplacer la molécule du token *)
    | Displace_mol_place b ->
       begin
         (
         match inputToken with
         | Token.Empty -> set_token inputToken p
         | Token.MolHolder m ->
            if b
            then set_token
                   (Token.set_mol (MoleculeHolder.move_forward m) inputToken) p
            else set_token
                   (Token.set_mol (MoleculeHolder.move_backward m) inputToken) p
         );
         NoAction
       end
    | _ ->  set_token inputToken p; NoAction
  else
    failwith "non empty place received a token from a transition"
 *)


(* ** Token reçu d'une transition. *)
(* **** TODO ajouter les effets de bords générés par les extensions *)
let add_token_from_transition (inputToken : Token.t) (place : t) =
  set_token inputToken place;;
(* ** Token ajouté par un broadcast de message. *)
(*    Il faudrait peut-être bien vérifier que la place reçoit des messages, que le message correspond, tout ça tout ça *)

let add_token_from_message (p : t) : unit =
  if is_empty p
  then set_token Token.empty p

(* ** token ajouté quand on attrape une molécule *)
(*on renvoie un booléen pour faire remonter facilement si le binding était possible ou pas *)
let add_token_from_binding (mol : Molecule.molecule) (p : t) : bool =
  if is_empty p
  then
    ( set_token (Token.make mol) p;
      true;)
  else
    false
    
(* ** remove the token from tokenHolder *)
  let pop_token (p : t) : Token.t =
    match p.tokenHolder with
    | EmptyHolder -> failwith "cannot pop token from empty place"
    | OccupiedHolder token ->
       ( remove_token p;
         token )

(* **** get_msg_receivers *)
  let rec get_msg_receivers (p : t) : AcidTypes.msg_format list =
    let rec aux exts = 
    match exts with
    | [] -> []
    | AcidTypes.Receive_msg_ext msg :: exts' -> msg :: aux exts'
    | _ :: exts' -> aux exts'
    in
    aux p.extensions

(* **** get_mol_catchers *)
  let get_catchers (p : t) : AcidTypes.catch_pattern list =
    let rec aux exts =
      match exts with
      | [] -> []
      | AcidTypes.Catch_ext cp :: exts' -> cp :: aux exts'
    | _ :: exts' -> aux exts'
    in
    aux p.extensions
                                    
      
(* ** to_json *)
  let to_json (p : t) =
    `Assoc
     [("token", token_holder_to_json p.tokenHolder);
      ("type", AcidTypes.place_type_to_yojson p.placeType)]
end;;
