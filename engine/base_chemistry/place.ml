(* * the place module *)

(*    Module qui gère les places. Une place a un type, et peut contenir un jeton.  *)

(* ** divers *)
type place_exts = Types.Acid.extension list

include Types.Place
(* **** make a place *)

(*    Filters valid grab extensions from the *)
(* extensions list. Could be rewriten with a  *)
(* filter *)

let make_grabers extensions =
  List.fold_left
    (fun gl acide ->
      match acide with
      | Types.Acid.Grab_ext g -> (
          match Graber.make g with Some g' -> g' :: gl | None -> gl)
      | _ -> gl)
    [] extensions

let make (exts_list : place_exts) (index : int) : t =
  let extensions = exts_list in

  let token =
    if List.mem Types.Acid.Init_with_token_ext extensions then
      Some (Token.make_empty ())
    else None
  and graber =
    match make_grabers extensions with [] -> None | g :: _ -> Some g
  in
  { token; extensions; index; graber; copy_buffer = "" }

let pop_token (p : t) : Token.t =
  match p.token with
  | None -> failwith "place.ml : cannot pop No_token"
  | Some token ->
      p.token <- None;
      token

let is_empty (p : t) : bool = p.token = None
let remove_token (p : t) : unit = p.token <- None
let set_token (token : Token.t) (p : t) : unit = p.token <- Some token

type transition_effect =
  | Message_effect of string
  | Release_effect of Molecule.t
[@@deriving show, yojson]

(* ** Token reçu d'une transition. *)
(* **** TODO ajouter les effets de bords générés par les extensions *)
let add_token_from_transition (inputToken : Token.t) (place : t) =
  if List.mem Types.Acid.Release_ext place.extensions then
    [ Release_effect (Token.get_mol inputToken) ]
  else (
    set_token inputToken place;
    [])

(* ** Token ajouté par un broadcast de message. *)
(*    Il faudrait peut-être bien vérifier que la place reçoit des messages, que le message correspond, tout ça tout ça *)

let add_token_from_message (p : t) : unit =
  if is_empty p then set_token (Token.make_empty ()) p

(* ** token ajouté quand on attrape une molécule *)
(*on renvoie un booléen pour faire remonter facilement si le binding était possible ou pas *)
let add_token_from_grab (token : Token.t) (p : t) : bool =
  if is_empty p then (
    set_token token p;
    true)
  else false

(* returns a list containing all the possible grab
   of the molecule by the grabers associated with index of the place *)

let get_possible_mol_grabs (mol : Molecule.t) (place : t) : (int * int) option =
  if is_empty place then
    match place.graber with
    | None -> None
    | Some g -> (
        match Graber.get_match_pos g mol with
        | Some n -> Some (n, place.index)
        | None -> None)
  else None

let has_copy_grabbed_ext (p : t) : bool =
  List.mem Types.Acid.Copy_grabbed_ext p.extensions

let is_copy_grabbed_ready (p : t) : bool =
  has_copy_grabbed_ext p &&
  match p.token with
  | None -> false
  | Some token -> Token.get_label token <> ""

let execute_copy_grabbed_step (p : t) : unit =
  match p.token with
  | None -> failwith "place.ml: copy_grabbed on empty place"
  | Some token ->
    let acid_char = Token.get_label token in
    p.copy_buffer <- p.copy_buffer ^ acid_char;
    p.token <- Some (Token.move_mol_forward token)

let extract_copy_buffer (p : t) : Token.t =
  let buf = p.copy_buffer in
  p.copy_buffer <- "";
  Token.make_at_mol_start buf
