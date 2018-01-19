open Misc_library

(* * the token module *)
   
(* Molecules are transformed into proteines by compiling them into a petri net. We define here the tokens used in the petri nets. Tokens go through transitions. *)

(* A token possesses a molecule (possibly empty), a pointer (int) to a *)
(* position of this molecule, and a label. *)
(* If a molecule is present in the MoleculeHolder and its pointer goes to *)
(* an acid of type Information, then that piece of information is defined *)
(* as the label. If not, the label is an empty string. *)


   
type t = int * Molecule.t
                 [@@deriving show, yojson]

type option_t = t option
                  [@@deriving show, yojson]
              
let is_empty ((_,m) : t) =  m = ""
                          
let make_empty () : t = (0,"")
                      
let make_at_mol_start (mol : Molecule.t) : t =
  (0, mol)
  
let make_at_mol_cut (mol1 : Molecule.t) (mol2 : Molecule.t) : t =
  (String.length mol1, mol1 ^ mol2)

let make (mol : Molecule.t) (pos : int) : t =
  (pos, mol)
  
let get_mol ((_,m) : t) : Molecule.t = m
                                     
let move_mol_forward ((i,m) : t) : t =
  if i < String.length m
  then (i+1,m)
  else (i,m)

let move_mol_backward ((i,m) : t) : t =
  if i>0
  then (i-1,m)
  else (i,m)
  
let cut_mol ((i,m) : t) : t*t =
  let m1 = Str.string_before m i
  and m2 = Str.string_after m i in
  ((i, m1),
   (0, m2))

(* insert source_tok inside dest_tok at the position 
     of the pointer in dest_tok. The new pointer will correspond
     to the position of the pointer in source_tok *)
let insert ((is,ms) : t) ((id,md) : t) : t =
  (is + id, Str.string_before md id ^ ms ^Str.string_after md id)
  
let get_label ((i,m) : t) =
  if i = String.length m
  then ""
  else Char.escaped (m.[i])
  
