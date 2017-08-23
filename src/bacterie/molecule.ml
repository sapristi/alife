open Proteine
open Acid_types
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
         (Proteine.TransitionInput (s,Filter_ilink (Atome.to_string a))) :: to_prot mol''
         
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
        let atom = Atome.of_char s.[n-i] in
        res := atom::(!res)
      done;
      !res
           
    let rec from_proteine (prot : Proteine.t) : t =
      match prot with
      | Proteine.Node Regular_place :: prot' ->
         Atome.A::A::A::(from_proteine prot')
      | Proteine.TransitionInput (s,Regular_ilink) :: prot' ->
         Atome.B::A::A::((string_to_acid_list s)@[D])@(from_proteine prot')
      | Proteine.TransitionInput (s,Split_ilink) :: prot' ->
         Atome.B::B::A::((string_to_acid_list s)@[D])@(from_proteine prot')
      | Proteine.TransitionInput (s,(Filter_ilink f)) :: prot' ->
         let a = Atome.of_char (f.[0]) in
         Atome.B::C::a::((string_to_acid_list s)@[D])@(from_proteine prot')
      | Proteine.TransitionOutput (s,Regular_olink) :: prot' ->
         Atome.C::A::A::((string_to_acid_list s)@[D])@(from_proteine prot')
      | Proteine.TransitionOutput (s,Bind_olink) :: prot' ->
         C::B::A::(from_proteine prot')
      | Proteine.TransitionOutput (s,Release_olink) :: prot' ->
         C::C::A::(from_proteine prot')
      | Proteine.Extension (Handle_ext s) :: prot' ->
         Atome.D::A::A::((string_to_acid_list s)@[D])@(from_proteine prot')
      | Proteine.Extension (Catch_ext s) :: prot' ->
         Atome.D::B::A::((string_to_acid_list s)@[D])@(from_proteine prot')
      | Proteine.Extension Release_ext :: prot' ->
         D::D::A::(from_proteine prot')
      | Proteine.Extension (Displace_mol_ext true) :: prot' ->
         D::B::B::(from_proteine prot')
      | Proteine.Extension (Displace_mol_ext false) :: prot' ->
         D::B::C::(from_proteine prot')
      | Proteine.Extension Init_with_token_ext :: prot' ->
         D::C::B::(from_proteine prot')
      | Proteine.Extension (Information_ext s) :: prot' ->
         Atome.D::D::B::((string_to_acid_list s)@[D])@(from_proteine prot')
      | [] -> []
  end
