

open Atome
   
(* * Molecule *)
(*    Defines a molecule built as a list of atoms. We have to *)
(*    interpret parts of the list as acids. *)

module Molecule =
  struct
    
                          
    type t = Atome.t list
                     [@@deriving show, yojson]
           
    let to_string (mol : t) : string =
      List.fold_right (fun a s -> (Atome.to_string a)^s) mol ""
      
    let rec extract_message_from_mol (mol : t) : (string*t) =
      match mol with
      | D::mol' ->  "",  mol'
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
         
  end
