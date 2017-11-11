open Misc_library
open Molecule
open Proteine
open Atome
(* * the token module *)
   
(* Molecules are transformed into proteines by compiling them into a petri net. We define here the tokens used in the petri nets. Tokens go through transitions. *)

(* A token possesses a molecule (possibly empty), a pointer (int) to a *)
(* position of this molecule, and a label. *)
(* If a molecule is present in the MoleculeHolder and its pointer goes to *)
(* an acid of type Information, then that piece of information is defined *)
(* as the label. If not, the label is an empty string. *)


   
module Token =
  struct
    type t =
      | No_token
      | Token
      | Mol_token of Molecule.t * Molecule.t
                                    [@@deriving show, yojson]

    let is_no_token (token :t) =
      token = No_token
      
    let is_empty (token : t) =
      match token with
      | No_token -> failwith "token.ml : cannot test empty on No_token"
      | Token -> true
      | Mol_token _ -> false

    let make_empty () : t =
      Token
      
    let make_at_mol_start (mol : Molecule.t) : t =
      if mol = []
      then make_empty ()
      else Mol_token ([], mol)
      
    let make_at_mol_cut (mol1 : Molecule.t) (mol2 : Molecule.t) : t =
      if mol1 = [] && mol2 = []
      then make_empty ()
      else Mol_token (mol1, mol2)

    let make (mol : Molecule.t) (pos : int) : t =
      let mol1, mol2 = cut_list mol pos in
      make_at_mol_cut mol1 mol2

      (* if token is empty : fail ?
         for now it returns empty mol *)
      
    let get_mol (token : t) : Molecule.t =
      match token with
      | No_token -> failwith "token.ml : cannot get_mol from empty_token"
      | Token -> []
      | Mol_token (m1,m2) ->
         let rec aux m1 m2 = 
           match m1,m2 with
           |[], m2 -> m2
           | a :: m1', m2 -> aux m1' (a::m2)
         in aux m1 m2
      
    let move_mol_forward (token : t) : t =
      match token with
      | No_token -> failwith "token.ml : cannot move_mol from empty_token"
      | Token -> Token
      | Mol_token (m1,m2) -> 
         match m1,m2 with
         | m1, a :: m2 -> Mol_token (a :: m1, m2)
         | _, [] -> token

    let move_mol_backward (token : t) : t =
      match token with
      | No_token -> failwith "token.ml : cannot move_mol from empty_token"
      | Token -> Token
      | Mol_token (m1,m2) -> 
           match m1,m2 with
           | a :: m2, m1 -> Mol_token (m2, a :: m1)
           | [], _ -> token

    let cut_mol (token : t) : t*t =
      match token with
      | No_token -> failwith "token.ml : cannot cut_mol from empty_token"
      | Token -> failwith "token.ml : cannot cut_mol from empty_token"
      | Mol_token (m1,m2) ->
         (
           if m1 = []
           then make_empty ()
           else Mol_token (m1, [])
         ),
         (
           if m2 = []
           then make_empty ()
           else Mol_token ([], m2);
         )
        

    (* insert source_tok inside dest_tok at the position 
     of the pointer in dest_tok. The new pointer will correspond
     to the position of the pointer in source_tok *)
    let insert (source_tok : t) (dest_tok : t) : t =
      match source_tok with
      | No_token -> failwith "token.ml : cannot insert No_token"
      | Token -> dest_tok
      | Mol_token (s1, s2) ->
         match dest_tok with
         | No_token -> failwith "token.ml : cannot insert into No_token"
         | Token -> source_tok
         | Mol_token (d1, d2) -> 
            Mol_token (s1 @ d1, s2 @ d2)
               
    let get_label (token : t) =
      match token with
      | No_token -> failwith "token.ml : cannot get_label from No_token"
      | Token -> ""
      | Mol_token (m1,m2) -> 
         match m1,m2 with
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
      
  (*
    let to_json token =
      if is_empty token
      then 
        `Assoc ["id", `Int token.global_id;
                "state", `String "empty token";
                "is_empty", `Bool true]
      else
        let m1, m2 = token.linked_mol in
        `Assoc ["id", `Int token.global_id;
                "state", `String "occupied token";
                "is_empty", `Bool false;
                "mol_1", `String (Molecule.to_string m1);
                "mol_2", `String (Molecule.to_string m2);]

    let from_json (token_json :Yojson.Basic.json) =
      match token_json with
      | `Assoc l ->
         let _, id = List.find (fun (x,_) -> x = "id") l
         and _, state = List.find (fun (x,_) -> x = "state") l in
         if state = "no"

      | _ -> failwith "token.ml from_json : bad json encoding"
                                             *)
      
  end
