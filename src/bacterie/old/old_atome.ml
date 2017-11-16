(* * atome *)

(* Atom are the basic building blocks of the world. *)
(* There are four types of atom. *)
(* Atoms can be assembled in a list, to form a molecule. *)

module Atome =
  struct
    type t =  A | B | C | D | E | F
                            [@@deriving show, yojson]

    let to_string (a : t) : string =
      match a with
      | A -> "A"
      | B -> "B"
      | C -> "C"
      | D -> "D"
      | E -> "E"
      | F -> "F"

    let of_char (c : char) : t = 
      match c with
      | 'A' -> A
      | 'B' -> B
      | 'C' -> C
      | 'D' -> D
      | 'E' -> E
      | 'F' -> F
      | c -> failwith ("cannot interpret char "^(Char.escaped c)^" as an atom")
           
  end
