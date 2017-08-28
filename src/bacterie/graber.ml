
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
open Atome
open Molecule
   
module Graber =
  struct

   
(* we keep the atom listfrom which the graber was build to easily *)
(* transform it back; this feature could be remove in future versions *)
  type t =
    { pattern : string;
      id : Atome.t list}
             [@@deriving show, yojson]

  type grab =
    | No_grab
    | Grab of int
            
  let build_from_atom_list (l : Atome.t list) : t =
    let rec aux l = 
      match l with
      | Atome.D::a::Atome.D::l' ->
         "\\("^ (Atome.to_string a) ^"\\)"^(aux l')
      | Atome.D::Atome.D :: l' ->
         ".+"^(aux l')
      | a :: l' ->
         (Atome.to_string a)^(aux l')
      | [] -> ""
    in
    {pattern = aux l;
     id = l}

  let build_from_string (s : string) : t =
    let atom_list = Molecule.string_to_acid_list s in
    build_from_atom_list atom_list

    
  let get_match_pos (mol : Molecule.t) (graber : t) : grab =
    let s = Molecule.to_string mol in
    let rex = Str.regexp graber.pattern in
    if Str.string_match rex s 0
    then
      try
        Grab (Str.group_beginning 1)
      with
      | Not_found -> No_grab
    else
      No_grab
      

end