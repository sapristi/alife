
(* * Graber *)

(* This file implements the graber, which allows a proteine to grab *)
(* a molecule by recognizing a regexp on his sequence of atoms *)

(* Here are the allowed commands : *)
(*  + atom : a specified atom *)
(*  + anything : any string of atoms, length > 0 *)
(*  + grab : the grab position *)
(*  + or : between two atoms, or combinator -> plus tard *)

(* Il y a plusieurs choix : *)
(*  + soit on interprète certaines séquences comme des commandes *)
(*    spéciales, et le reste comme de atomes (ce qui limite *)
(*    les séquences qu'on peut reconnaître) *)
(*  + soit on insère aussi un marqueur pour les atomes (à la *)
(*    manière du symbole d'échappement \ pour les caractères *)
(*    spéciaux) *)

module Graber =
  struct

(* *** graber type *)
(* we keep the atom list from which the graber was build to easily *)
(* transform it back; this feature could be remove in future versions *)
    type t = string
     
        [@@deriving yojson]

(* *** grab type : represents the result of a grab tentative  *)
(*  No_grab means the grab failed *)
(*  Grab pos means a grab is possible at position pos *)
  type grab =
    | No_grab
    | Grab of int


(* *** build_from_atom_list *)
(*     Transforms a list of atoms into a string representing a regular *)
(*     expression. *)

(*     Special expressions  *)
(*      + an atome surrounded by two F atoms :  *)
(*        the grabing point, that is the place at which the grabed *)
(*        molecule will be split *)

(*      + two F atoms : *)
(*        any non-empty sequence of atoms *)

  let grab_location_re = Str.regexp "F\\(.\\)F"
  and wildcard_re = Str.regexp "FF"
            
  let rec build_re (m : t) : string =
    if m = ""
    then "$"
    else
      if Str.string_match grab_location_re m 0 
      then 
        let a = Str.matched_group 1 m in
        let m' = (Str.string_after m (Str.match_end ())) in
        "\\("^a^"\\)"^(build_re m')
      else if Str.string_match wildcard_re m 0
      then 
        let m' = (Str.string_after m (Str.match_end ())) in
        ".*"^(build_re m')
      else
        (Str.string_before m 1) ^ (build_re (Str.string_after m 1))

    
  let get_match_pos (mol : string) (graber : t) : grab =
    let rex = Str.regexp (build_re graber) in
    if Str.string_match rex mol 0
    then
      try
        Grab (Str.group_beginning 1)
      with
      | Not_found -> No_grab
    else
      No_grab
      
end
