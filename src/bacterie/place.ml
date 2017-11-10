open Misc_library
open Molecule
open Proteine.Proteine
open Proteine
open Token
open Acid_types
open Graber
   
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
       extensions : AcidTypes.extension_type list;
       global_id : int;
       grabers : Graber.t list;
      }
        [@@deriving show]
(* **** make a place *)
(* ***** DONE allow place extension to initialise the place with an empty token *)

    let make (place_with_exts : AcidTypes.place_type *  place_exts)
        : t =
      let placeType, extensions = place_with_exts in
      let tokenHolder = 
        if List.mem AcidTypes.Init_with_token_ext extensions
        then
          OccupiedHolder (Token.make_empty ())
        else
          EmptyHolder
      and grabers =
        List.fold_left
          (fun l acide ->
            match acide with AcidTypes.Grab_ext g -> g::l | _ -> l)
          [] extensions
      in
        {tokenHolder;
         placeType;
         extensions;
         global_id = idProvider#get_id ();
         grabers}
     
    let pop_token_for_transition (p : t) : Token.t =
      match p.tokenHolder with
      | EmptyHolder -> failwith "asking for token from empty place"
      | OccupiedHolder token ->
         p.tokenHolder <- EmptyHolder; token
         
         
    let is_empty (p : t) : bool =
      p.tokenHolder = EmptyHolder
      
    let remove_token (p : t) : unit=
      p.tokenHolder <- EmptyHolder
      
    let set_token (token : Token.t) (p : t) : unit =
      p.tokenHolder <- OccupiedHolder token


(* ** Token reçu d'une transition. *)
(* **** TODO ajouter les effets de bords générés par les extensions *)
    let add_token_from_transition (inputToken : Token.t) (place : t) =
      set_token inputToken place;;

      
(* ** Token ajouté par un broadcast de message. *)
(*    Il faudrait peut-être bien vérifier que la place reçoit des messages, que le message correspond, tout ça tout ça *)

    let add_token_from_message (p : t) : unit =
      if is_empty p
      then set_token (Token.make_empty ()) p
      
(* ** token ajouté quand on attrape une molécule *)
(*on renvoie un booléen pour faire remonter facilement si le binding était possible ou pas *)
    let add_token_from_grab (token : Token.t) (p : t)
        : bool =
      if is_empty p
      then
        ( set_token token p;
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

(* returns a list containing all the possible grab
   of the molecule by the grabers associated with index of the place *)
        
    let get_possible_mol_grabs (mol : Molecule.t) (place : t) (i : int)
        : ((Graber.grab * int) list) =
      if is_empty place
      then
        List.fold_left
          (fun g_list g ->
            match Graber.get_match_pos mol g with
            | Graber.Grab n -> (Graber.Grab n, i) :: g_list
            | Graber.No_grab -> g_list
          ) [] place.grabers
      else
        []
      
(* ** to_json *)
    let to_json (p : t) =
      `Assoc
       [("id", `Int p.global_id);
        ("token", token_holder_to_json p.tokenHolder);
        ("extensions"), `List (List.map AcidTypes.extension_type_to_yojson p.extensions)]
  end;;
