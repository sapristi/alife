open Misc_library
open Molecule
open Proteine
open Atome
(* * the token module *)
   
(* Molecules are transformed into proteines by compiling them into a petri net. We define here the tokens used in the petri nets. Tokens go through transitions. *)

(* A token possesses a molecule (possibly empty), a pointer (int) to a  *)
(* position of this molecule, and a label. *)
(* If a molecule is present in the MoleculeHolder and its pointer goes to *)
(* an acid of type Information, then that piece of information is defined *)
(* as the label. If not, the label is an empty string. *)

module Token =
  struct

    type t =
      {mutable linked_mol : Molecule.t * Molecule.t;
       global_id : int}
                          [@@deriving show]
    let is_empty (token : t) =
      token.linked_mol = ([], [])

    let make_at_mol_start (mol : Molecule.t) : t =
      {linked_mol = ([], mol);
       global_id = idProvider#get_id ();}

    let make_empty () : t =
      {linked_mol = ([], []);
       global_id = idProvider#get_id ();}
      
    let make_at_mol_cut (mol1 : Molecule.t) (mol2 : Molecule.t) : t =
      {linked_mol = (mol1, mol2);
       global_id = idProvider#get_id ();}

    let make (mol : Molecule.t) (pos : int) : t =
      let mol1, mol2 = cut_list mol pos in
      make_at_mol_cut mol1 mol2
      
    let get_mol (token : t) : Molecule.t =
      let rec aux split_mol = 
        match split_mol with
        |[], m2 -> m2
        | a :: m1', m2 -> aux (m1',(a::m2))
      in aux token.linked_mol
      
    let move_mol_forward (token : t) : unit  =
      token.linked_mol <- 
        match token.linked_mol with
        | m1, a :: m2 -> a :: m1, m2
        | _, [] -> token.linked_mol

    let move_mol_backward (token : t) : unit =
      token.linked_mol <- 
        match token.linked_mol with
        | a :: m2, m1 -> m2, a :: m1
        | [], _ -> token.linked_mol

    let cut_mol (token : t) : t*t =
      let m1, m2 = token.linked_mol in
      {linked_mol = (m1, []);
       global_id = idProvider#get_id ();},
      
      {linked_mol = ([], m2);
       global_id = idProvider#get_id ();}
      

    (* insert source_tok inside dest_tok at the position 
     of the pointer in dest_tok. The new pointer will correspond
     to the position of the pointer in source_tok *)
    let insert (source_tok : t) (dest_tok : t) : t =
      let (s1, s2), (d1, d2) = source_tok.linked_mol, dest_tok.linked_mol in 
      {linked_mol = (s1 @ d1, s2 @ d2);
       global_id =  idProvider#get_id ();}
               
    let get_label (token : t) =
      match token.linked_mol with
      | _, a :: m2 -> Atome.to_string a
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
      if is_empty token
      then 
        `Assoc ["id", `Int token.global_id;
                "is_empty", `Bool true]
      else
        let m1, m2 = token.linked_mol in
        `Assoc ["id", `Int token.global_id;
                "is_empty", `Bool false;
                "mol_1", `String (Molecule.to_string m1);
                "mol_2", `String (Molecule.to_string m2);]
                      
  end
