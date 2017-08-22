
open Proteine
open AcidTypes

module Atom =
  struct
    type t =  A | B | C | D
                            [@@deriving show, yojson]
                               
    let to_string (a : t) : string =
      match a with
      | A -> "A"
      | B -> "B"
      | C -> "C"
      | D -> "D"
        
  end

   
module Molecule =
  struct
    
                          
    type t = Atom.t list
                     [@@deriving show, yojson]
           
    let to_string (mol : t) : string =
      List.fold_right (fun a s -> (Atom.to_string a)^s) mol ""
      
    let rec extract_message_from_mol (mol : t) : (string*t) =
      match mol with
      | D::mol' ->  "",  mol'
      | a::mol' ->
         let (s, mol'') = extract_message_from_mol mol' in
         (Atom.to_string a)^s,mol'' 
      | [] -> failwith "can't read message in mol"
            
            
    let rec to_prot (mol : t) : Proteine.acid list =
      match mol with
        
      | A::A::A::mol' -> (Proteine.Node Regular_place) :: to_prot mol'
                       
      | B::A::A::mol' ->
         let s,mol'' = extract_message_from_mol mol' in
         (Proteine.TransitionInput (s,Regular_ilink)) :: (to_prot mol'')
         
      | B::B::A::mol' ->
         let s,mol'' = extract_message_from_mol mol' in
         (Proteine.TransitionInput (s,Split_ilink)) :: (to_prot mol'')
         
      | B::C::a::mol' ->
         let s,mol'' = extract_message_from_mol mol' in
         (Proteine.TransitionInput (s,Filter_ilink (atom_to_string a))) :: to_prot mol''
         
      | C::A::A::mol'->
         let s,mol'' = extract_message_from_mol mol' in
         (Proteine.TransitionOutput (s,Regular_olink)) :: to_prot mol''
         
      | C::B::A::mol'->
         let s,mol'' = extract_message_from_mol mol' in
         (Proteine.TransitionOutput (s,Bind_olink)) :: to_prot mol''
         
      | C::C::A::mol'->
         let s,mol'' = extract_message_from_mol mol' in
         (Proteine.TransitionOutput (s,Release_olink)) :: to_prot mol''
         
      | D::A::A::mol'->
         let s,mol'' = extract_message_from_mol mol' in
         (Proteine.Extension (Handle_ext s)) :: to_prot mol''
         
      | D::B::A::mol'->
         let s,mol'' = extract_message_from_mol mol' in
         (Proteine.Extension (Catch_ext s)) :: to_prot mol''
         
      | D::D::A::mol'->
         (Proteine.Extension Release_ext) :: to_prot mol'
        
      | D::B::B::mol'->
         (Proteine.Extension (Displace_mol_ext true)) :: to_prot mol'
        
      | D::B::C::mol'->
         (Proteine.Extension (Displace_mol_ext false)) :: to_prot mol'
        
      | D::C::B::mol'->
         (Proteine.Extension Init_with_token_ext) :: to_prot mol'
        
      | D::D::B::mol' ->
         let s,mol'' = extract_message_from_mol mol' in
         (Proteine.Extension (Information_ext s)) :: to_prot mol''
         
      | _ -> []

    let string_to_acid_list (s : string) : t =
      let n = String.length s in
      let res = ref [] in
      for i=1 to n do
        let atom = 
          match s.[n-i] with
          | 'A' -> A
          | 'B' -> B
          | 'C' -> C
          | 'D' -> D
          | _ -> failwith "cannot interpret this string as atoms"
        in
        res := atom::(!res)
      done;
      !res
           
    let rec from_proteine (prot : Proteine.t) : t =
      match prot with
      | Proteine.Node Regular_place :: prot' ->
         A::A::A::(from_proteine prot')
      | Proteine.TransitionInput (s,Regular_ilink) :: prot' ->
         B::A::A::((string_to_acid_list s)@[D])@(from_proteine prot')
      | Proteine.TransitionInput (s,Split_ilink) :: prot' ->
         B::B::A::((string_to_acid_list s)@[D])@(from_proteine prot')
      | Proteine.TransitionInput (s,Filter_ilink (atom_to_string a))
      | [] -> []
  end
