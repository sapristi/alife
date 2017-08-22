type atom = A | B | C | D
type molecule = atom list

              
module AcidTypes =
  struct

(* ** transition_input *)
    type transition_input_type = 
      | Regular_ilink
      | Split_ilink
      | Filter_ilink of string
                          [@@deriving show, yojson]
                      
(* ** transition_output *)
    type transition_output_type = 
      | Regular_olink
      | Bind_olink
      | Release_olink
[@@deriving show, yojson]



(* ** extension *)
(* Types used by the extensions. Usefull to use custom types for easier potential changes later on.  *)
    type handle_id = string
                       [@@deriving show, yojson]
    type bind_pattern = string
                           [@@deriving show, yojson]
    type receive_pattern = string
                             [@@deriving show, yojson]
    type msg_format = string
                        [@@deriving show, yojson]
                    
    type extension_type =
      | Handle_ext of handle_id
      | Catch_ext of bind_pattern
      | Receive_msg_ext of msg_format
      | Release_ext
      | Send_msg_ext of msg_format
      | Displace_mol_ext of bool
      | Init_with_token
      | Information_ext of string
                         [@@deriving show, yojson]
  end;;

open AcidTypes
   
type acid = 
  | Node 
  | TransitionInput of string * AcidTypes.transition_input_type
  | TransitionOutput of string * AcidTypes.transition_output_type
  | Extension of AcidTypes.extension_type
                   [@@deriving show, yojson]

let atom_to_string (a : atom) : string =
  match a with
  | A -> "A"
  | B -> "B"
  | C -> "C"
  | D -> "D"
               
let molecule_to_string (mol : molecule) : string =
  List.fold_right (fun a s -> (atom_to_string a)^s) mol ""

let rec extract_message_from_mol (mol : molecule) : (string*molecule) =
  match mol with
  | D::mol' ->  "",  mol'
  | a::mol' ->
     let (s, mol'') = extract_message_from_mol mol' in
     (atom_to_string a)^s,mol'' 
  | [] -> failwith "can't read message in mol"


let rec molecule_to_prot (mol : molecule) : acid list =
  match mol with
    
  | A::A::A::mol' -> Node :: molecule_to_prot mol'
                   
  | B::A::A::mol' ->
     let s,mol'' = extract_message_from_mol mol' in
     (TransitionInput (s,Regular_ilink)) :: (molecule_to_prot mol'')
    
  | B::B::A::mol' ->
     let s,mol'' = extract_message_from_mol mol' in
     (TransitionInput (s,Split_ilink)) :: (molecule_to_prot mol'')
    
  | B::C::a::mol' ->
     let s,mol'' = extract_message_from_mol mol' in
     (TransitionInput (s,Filter_ilink (atom_to_string a))) :: molecule_to_prot mol''
    
  | C::A::A::mol'->
     let s,mol'' = extract_message_from_mol mol' in
     (TransitionOutput (s,Regular_olink)) :: molecule_to_prot mol''
    
  | C::B::A::mol'->
     let s,mol'' = extract_message_from_mol mol' in
     (TransitionOutput (s,Bind_olink)) :: molecule_to_prot mol''
    
  | C::C::A::mol'->
     let s,mol'' = extract_message_from_mol mol' in
     (TransitionOutput (s,Release_olink)) :: molecule_to_prot mol''
    
  | D::A::A::mol'->
     let s,mol'' = extract_message_from_mol mol' in
     (Extension (Handle_ext s)) :: molecule_to_prot mol''
     
  | D::B::A::mol'->
     let s,mol'' = extract_message_from_mol mol' in
     (Extension (Catch_ext s)) :: molecule_to_prot mol''
     
  | D::C::A::mol'->
     let s,mol'' = extract_message_from_mol mol' in
     (Extension (Receive_msg_ext s)) :: molecule_to_prot mol''
     
  | D::D::A::mol'->
     (Extension Release_ext) :: molecule_to_prot mol'
     
  | D::A::B::mol'->
     let s,mol'' = extract_message_from_mol mol' in
     (Extension (Send_msg_ext s)) :: molecule_to_prot mol''
     
  | D::B::B::mol'->
     (Extension (Displace_mol_ext true)) :: molecule_to_prot mol'

  | D::B::C::mol'->
     (Extension (Displace_mol_ext false)) :: molecule_to_prot mol'

  | D::C::B::mol'->
     (Extension Init_with_token) :: molecule_to_prot mol'

  | D::D::B::mol' ->
     let s,mol'' = extract_message_from_mol mol' in
     (Extension (Information_ext s)) :: molecule_to_prot mol''
     
  | _ -> []
