(* * this file *)
  
(*   proteine.ml defines the basic properties of a proteine, some *)
(*   functions to help build a petri-net out of it and a module to help it *)
(*   get managed by a petri-net (i.e. simulate chemical reactions *)

(* * preamble : load libraries *)


open Graber
open Proteine
open AcidTypes
   
module Molecule =
  struct
    
    type t = string
           [@@deriving yojson] 
          
    let atoms = "[A-E]"

    let place_pt = "AAA"
    and ia_reg_pt = "BAA"
    and ia_split_pt = "BBA"
    and ia_filter_pt = "BC"
    and oa_reg_pt = "CAA"
    and oa_bind_pt = "CBA"
    and oa_move_fw_pt = "CCA"
    and oa_move_bw_pt = "CCB"
    and ext_grab_pt = "ABA"
    and ext_rel_pt = "ABB"
    and ext_tinit_pt = "ABC"
    and msg_end_pt = "DDD"
    and msg_body_pt = "\\([^DDD]*\\)"
              
    let place_re = Str.regexp place_pt
    and ia_reg_re = Str.regexp (ia_reg_pt^"\\(.*\\)"^msg_end_pt)
    and ia_split_re = Str.regexp (ia_split_pt^"\\(.*\\)"^msg_end_pt)
    and ia_filter_re = Str.regexp
                     (ia_filter_pt^"\\("^atoms^"\\)"^msg_end_pt)
    and oa_reg_re = Str.regexp (oa_reg_pt^"\\(.*\\)"^msg_end_pt)
    and oa_bind_re = Str.regexp (oa_bind_pt^"\\(.*\\)"^msg_end_pt)
    and oa_move_fw_re = Str.regexp (oa_move_fw_pt^"\\(.*\\)"^msg_end_pt)
    and oa_move_bw_re = Str.regexp (oa_move_bw_pt^"\\(.*\\)"^msg_end_pt)
    and ext_grab_re = Str.regexp (ext_grab_pt^"\\(.*\\)"^msg_end_pt)
    and ext_rel_re = Str.regexp ext_rel_pt
    and ext_tinit_re = Str.regexp ext_tinit_pt
                     
    let rec mol_parser (s : t) : Proteine.t =
      if s = ""
      then []
      else
        if Str.string_match place_re s 0
        then
          Place :: (mol_parser (Str.string_after s (Str.match_end ())))
      
        else if Str.string_match ia_reg_re s 0
        then
          let tid = Str.matched_group 1 s in
          let s' = (Str.string_after s (Str.match_end ())) in
          (InputArc (tid , Regular_iarc)) :: (mol_parser s')
          
        else if Str.string_match ia_split_re s 0
        then
          let tid = Str.matched_group 1 s in
          let s' = (Str.string_after s (Str.match_end ())) in
          (InputArc (tid , Split_iarc)) :: (mol_parser s')
          
        else if Str.string_match ia_filter_re s 0
        then
          let f = Str.matched_group 1 s
          and tid = Str.matched_group 2 s in
          let s' = (Str.string_after s (Str.match_end ())) in
          (InputArc (tid , Filter_iarc f)) :: (mol_parser s')
          
        else if Str.string_match oa_reg_re s 0
        then 
          let tid = Str.matched_group 1 s in
          let s' = (Str.string_after s (Str.match_end ())) in
          (OutputArc (tid , Regular_oarc)) :: (mol_parser s')
          
        else if Str.string_match oa_bind_re s 0
        then 
          let tid = Str.matched_group 1 s in
          let s' = (Str.string_after s (Str.match_end ())) in
          (OutputArc (tid , Bind_oarc)) :: (mol_parser s')
          
        else if Str.string_match oa_move_fw_re s 0
        then
          let tid = Str.matched_group 2 s in
          let s' = (Str.string_after s (Str.match_end ())) in
          (OutputArc (tid , Move_oarc true)) :: (mol_parser s')
          
        else if Str.string_match oa_move_bw_re s 0
        then
          let tid = Str.matched_group 2 s in
          let s' = (Str.string_after s (Str.match_end ())) in
          (OutputArc (tid , Move_oarc false)) :: (mol_parser s')
          
        else if Str.string_match ext_grab_re s 0
        then
          let g = Str.matched_group 1 s in
          let s' = (Str.string_after s (Str.match_end ())) in
          (Extension (Grab_ext g)) :: (mol_parser s')
          
        else if Str.string_match ext_rel_re s 0
        then
          Extension Release_ext :: (mol_parser (Str.string_after s (Str.match_end ())))
      
        else if Str.string_match ext_tinit_re s 0
        then
          Extension Init_with_token_ext :: (mol_parser (Str.string_after s (Str.match_end ())))
      
        else 
          mol_parser (Str.string_after s 1)
      
    let to_proteine (m : t) : Proteine.t = 
      mol_parser m
      
      
    let rec of_proteine (p : Proteine.t) : t =
      let acid_to_mol (a : acid) : t = 
        match a with
        | Place  ->
           place_pt 
        | InputArc (s,Regular_iarc)  ->
           ia_reg_pt ^ s ^ msg_end_pt
        | InputArc (s,Split_iarc) ->
           ia_split_pt ^ s ^ msg_end_pt 
        | InputArc (s,(Filter_iarc f))  ->
           ia_filter_pt ^ f ^ s ^msg_end_pt
        | OutputArc (s,Regular_oarc) ->
           oa_reg_pt ^ s ^ msg_end_pt
        | OutputArc (s,Bind_oarc)  ->
           oa_bind_pt ^ s ^ msg_end_pt
        | OutputArc (s,Move_oarc true) ->
           oa_move_fw_pt ^ s^ msg_end_pt
        | OutputArc (s,Move_oarc false)  ->
           oa_move_bw_pt ^ s^ msg_end_pt
        | Extension Release_ext  ->
           ext_rel_pt 
        | Extension Init_with_token_ext  ->
           ext_tinit_pt 
        | Extension (Grab_ext g) ->
           ext_grab_pt ^ g ^msg_end_pt
      in 
      match p with
      | a :: p' ->
         (acid_to_mol a) ^ (of_proteine p')
      | [] -> ""
end;;
