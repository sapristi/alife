
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
open Molecule

module Graber =
  struct

(* *** graber type *)
(* we keep the atom list from which the graber was build to easily *)
(* transform it back; this feature could be remove in future versions *)
    type t =
      {raw : Atome.t list;
       re : string;
      }
       
     

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

            
  let rec atom_list_to_re (m : Atome.t list) : string =
    match m with
    | F :: a :: F :: m' ->
       "\\("^(Atome.to_string a)^"\\)"^(atom_list_to_re m')
    | F::F::m' ->
       ".*"^(atom_list_to_re m')
    | a :: m' -> (Atome.to_string a)^(atom_list_to_re m')
    | [] -> ""
            
  let make (raw : Atome.t list) :t =
    let re = (atom_list_to_re raw) in {raw;re}

    
  let get_match_pos (mol : Molecule.t) (graber : t) : grab =
    let rex = Str.regexp (graber.re)
    and mol_str = Molecule.to_string mol in
    if Str.string_match rex mol_str 0
    then
      try
        Grab (Str.group_beginning 1)
      with
      | Not_found -> No_grab
    else
      No_grab

  let to_yojson (g :t) : Yojson.Safe.json =
    Molecule.to_yojson g.raw

  let of_yojson (json : Yojson.Safe.json) : ((t,string) result) =
    match Molecule.of_yojson json with
    | Ok m -> Ok (make m)
    | Error s -> Error s
    
end
