(* tezzre *)


module Atome =
  struct
    type t =  A | B | C | D
                            [@@deriving show, yojson]

    let to_string (a : t) : string =
      match a with
      | A -> "A"
      | B -> "B"
      | C -> "C"
      | D -> "D"

    let of_char (c : char) : t = 
      match c with
      | 'A' -> A
      | 'B' -> B
      | 'C' -> C
      | 'D' -> D
      | _ -> failwith "cannot interpret this char as an atom"
           
  end