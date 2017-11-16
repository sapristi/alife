open Misc_library
open Molecule
open Proteine
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
      | Token of int * Molecule.t
                                    [@@deriving yojson]
    let is_no_token (token :t) =
      token = No_token
      
    let is_empty (token : t) =
      match token with
      | No_token -> failwith "token.ml : cannot test empty on No_token"
      | Token (i,m)-> (m = "")
      

    let make_empty () : t =
      Token (0,"")
      
    let make_at_mol_start (mol : Molecule.t) : t =
      Token (0, mol)
      
    let make_at_mol_cut (mol1 : Molecule.t) (mol2 : Molecule.t) : t =
      Token (String.length mol1, mol1 ^ mol2)

    let make (mol : Molecule.t) (pos : int) : t =
      Token (pos, mol)

      (* if token is empty : fail ?
         for now it returns empty mol *)
      
    let get_mol (token : t) : Molecule.t =
      match token with
      | No_token -> failwith "token.ml : cannot get_mol from empty_token"
      | Token (i,m) -> m
      
    let move_mol_forward (token : t) : t =
      match token with
      | No_token -> failwith "token.ml : cannot move_mol from empty_token"
      | Token (i,m) -> 
         if i < String.length m
         then Token(i+1,m)
         else Token(i,m)

    let move_mol_backward (token : t) : t =
      match token with
      | No_token -> failwith "token.ml : cannot move_mol from empty_token"
      | Token (i,m) -> 
         if i>0
         then Token(i-1,m)
         else Token(i,m)
        
    let cut_mol (token : t) : t*t =
      match token with
      | No_token -> failwith "token.ml : cannot cut_mol from empty_token"
      | Token (i,m) ->
         let m1 = Str.string_before m i
         and m2 = Str.string_after m i in
         (Token (i, m1),
          Token (0, m2))
        
        

    (* insert source_tok inside dest_tok at the position 
     of the pointer in dest_tok. The new pointer will correspond
     to the position of the pointer in source_tok *)
    let insert (source_tok : t) (dest_tok : t) : t =
      match source_tok with
      | No_token -> failwith "token.ml : cannot insert No_token"
      | Token (is, ms) ->
         match dest_tok with
         | No_token -> failwith "token.ml : cannot insert into No_token"
         | Token (id, md) -> 
            Token (is + id, Str.string_before md id ^ md ^Str.string_after md id)
               
    let get_label (token : t) =
      match token with
      | No_token -> failwith "token.ml : cannot get_label from No_token"
      | Token  (i,s) -> 
         if i = String.length s
         then ""
         else Char.escaped (s.[i]) 
           
  end
