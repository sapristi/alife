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
      | Token of (Molecule.t * Molecule.t)
                                    [@@deriving yojson]
    let is_no_token (token :t) =
      token = No_token
      
    let is_empty (token : t) =
      match token with
      | No_token -> failwith "token.ml : cannot test empty on No_token"
      | Token (m1,m2)-> (m1 = [] && m2 = [])
      

    let make_empty () : t =
      Token ([],[])
      
    let make_at_mol_start (mol : Molecule.t) : t =
      Token ([], mol)
      
    let make_at_mol_cut (mol1 : Molecule.t) (mol2 : Molecule.t) : t =
      Token (List.rev mol1, mol2)

    let make (mol : Molecule.t) (pos : int) : t =
      let m1, m2 = cut_list mol pos in
      make_at_mol_cut m1 m2


      (* if token is empty : fail ?
         for now it returns empty mol *)
      
    let get_mol (token : t) : Molecule.t =
      match token with
      | No_token -> failwith "token.ml : cannot get_mol from empty_token"
      | Token (m1,m2) -> (List.rev m1)@(m2)
      
    let move_mol_forward (token : t) : t =
      match token with
      | No_token -> failwith "token.ml : cannot move_mol from empty_token"
      | Token (m1,m2) -> 
         match m2 with
         | [] -> Token (m1, m2)
         | a :: m2' -> Token (a :: m1, m2')
         
    let move_mol_backward (token : t) : t =
      match token with
      | No_token -> failwith "token.ml : cannot move_mol from empty_token"
      | Token (m1,m2) ->
         match m1 with
         | [] -> Token (m1, m2)
         | a :: m1' -> Token (m1', a:: m2)
        
    let cut_mol (token : t) : t*t =
      match token with
      | No_token -> failwith "token.ml : cannot cut_mol from empty_token"
      | Token (m1,m2) ->
         (Token (m1, []),
          Token ([], m2))
        
        

    (* insert source_tok inside dest_tok at the position 
     of the pointer in dest_tok. The new pointer will correspond
     to the position of the pointer in source_tok *)
    let insert (source_tok : t) (dest_tok : t) : t =
      match source_tok with
      | No_token -> failwith "token.ml : cannot insert No_token"
      | Token (s1, s2) ->
         match dest_tok with
         | No_token -> failwith "token.ml : cannot insert into No_token"
         | Token (d1, d2) -> 
            Token (s1 @ d1, s2 @ d2)
               
    let get_label (token : t) =
      match token with
      | No_token -> failwith "token.ml : cannot get_label from No_token"
      | Token  (_,[]) -> ""
      | Token  (_,a::_) -> Atome.to_string a
  end
