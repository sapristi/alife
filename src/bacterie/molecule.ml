(* * atome *)

(* Atom are the basic building blocks of the world. *)
(* There are four types of atom. *)
(* Atoms can be assembled in a list, to form a molecule. *)

module Atome =
  struct
    type t =  A | B | C | D | E | F

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



open Atome
   
(* * Molecule *)
(*    Defines a molecule built as a list of atoms. We have to *)
(*    interpret parts of the list as acids. (this is done in proteine.ml) *)


module Molecule =
  struct
    
                          
    type t = Atome.t list
           
    let to_string (mol : t) : string =
      List.fold_right (fun a s -> (Atome.to_string a)^s) mol ""


(* function to extract a string representing information
from a molecule. 
The list of atoms is directly transformed into a string.
When an atom of type D is read, the transcription stops 
and the resulting string is returned with the remaining 
molecule     *)      

    let rec extract_message_from_mol (mol : t) : (string*t) =
      match mol with
      | F::F::F::mol' ->  "",  mol'
      | a::mol' ->
         let (s, mol'') = extract_message_from_mol mol' in
         (Atome.to_string a)^s,mol'' 
      | [] -> failwith "can't read message in mol"
            
            

    let string_to_acid_list (s : string) : t =
      let n = String.length s in
      let res = ref [] in
      for i=1 to n do
        let atom = Atome.of_char s.[n-i] in
        res := atom::(!res)
      done;
      !res
         

    let string_to_message_mol (s : string) : t =
      (string_to_acid_list s)@[F;F;F]

    let to_yojson (mol :t) : Yojson.Safe.json =
      `String (String.concat "" ((List.map Atome.to_string) mol))

    let of_yojson (json : Yojson.Safe.json) : ((t, string) result)  =
      match json with
      | `String mol_str ->
         Ok (string_to_acid_list mol_str)
      | _ -> Error "molecule.ml : bad json in from_json"
      
  end
