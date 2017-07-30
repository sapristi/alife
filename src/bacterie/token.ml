open Molecule.Molecule
open Molecule
(* * the token module *)
   
(* Molecules are transformed into proteines by compiling them into a petri net. We define here the tokens used in the petri nets. Tokens go through transitions. *)

(* A token possesses a molecule (possibly empty), a pointer (int) to a  *)
(* position of this molecule, and a label. *)
(* If a molecule is present in the MoleculeHolder and its pointer goes to *)
(* an acid of type Information, then that piece of information is defined *)
(* as the label. If not, the label is an empty string. *)

module Token =
  struct

    type t = molecule * molecule
                          [@@deriving show]
    let is_empty token =
      token = ([], [])

    let empty = ([], [])

    let make mol : t =
      ([], mol)

    let move_mol_forward token =
      match token with
      | m1, a :: m2 -> a :: m1, m2
      | _, [] -> token

    let move_mol_backward token =
      match token with
      | a :: m2, m1 -> m2, a :: m1
      | [], _ -> token

    let cut_mol token =
      let m1, m2 = token in
      (m1, []), ([], m2)

    (* insert source_tok inside dest_tok at the position 
     of the pointer in dest_tok. The new pointer will correspond
     to the position of the pointer in source_tok *)
    let insert source_tok dest_tok =
      let (s1, s2), (d1, d2) = source_tok, dest_tok in 
      (s1 @ d1, s2 @ d2)
               
    let get_label token =
      match token with
      | _, Extension (AcidTypes.Information s) :: m2 -> s
      | _ -> ""
           

    let to_string (token : t) : string =
      let mol_desc =
        if is_empty token
        then "empty"
        else "molecule"
      and label_desc = get_label token
      in
      "token ("^mol_desc^") ("^label_desc^")"
      
                      
    let to_json token =
      let mol_desc =
        if is_empty token
        then "empty"
        else "molecule"
      and label_desc = get_label token
      in
      `List [`String "token";
             `String mol_desc;
             `String label_desc]
                      
  end
