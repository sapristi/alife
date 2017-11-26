(* * this file *)
  
(*   proteine.ml defines the basic properties of a proteine, some *)
(*   functions to help build a petri-net out of it and a module to help it *)
(*   get managed by a petri-net (i.e. simulate chemical reactions *)

(* * preamble : load libraries *)





    
type t = string
           [@@deriving yojson] 
       
let atoms = "[A-F]"

let place_id = "AAA"
and ia_reg_id = "BAA"
and ia_split_id = "BBA"
and ia_filter_id = "BC"
and ia_filter_empty_id = "BAB"
and oa_reg_id = "CAA"
and oa_bind_id = "CBA"
and oa_move_fw_id = "CCA"
and oa_move_bw_id = "CCB"
and ext_grab_id = "ABA"
and ext_rel_id = "ABB"
and ext_tinit_id = "ABC"
and msg_end_id = "DDF"
               
let place_re = "^"^place_id^"(.*)"
and ia_reg_re = "^"^ia_reg_id^"(.*?)"^msg_end_id^"(.*)"
and ia_split_re = "^"^ia_split_id^"(.*?)"^msg_end_id^"(.*)"
and ia_filter_re = "^"^ia_filter_id^"("^atoms^")(.*?)"^msg_end_id^"(.*)"
and ia_filter_empty_re = "^"^ia_filter_empty_id^"(.*?)"^msg_end_id^"(.*)"
and oa_reg_re = "^"^oa_reg_id^"(.*?)"^msg_end_id^"(.*)"
and oa_bind_re = "^"^oa_bind_id^"(.*?)"^msg_end_id^"(.*)"
and oa_move_fw_re = "^"^oa_move_fw_id^"(.*?)"^msg_end_id^"(.*)"
and oa_move_bw_re = "^"^oa_move_bw_id^"(.*?)"^msg_end_id^"(.*)"
and ext_grab_re = "^"^ext_grab_id^"(.*?)"^msg_end_id^"(.*)"
and ext_rel_re =  "^"^ext_rel_id^"(.*)"
and ext_tinit_re =  "^"^ext_tinit_id^"(.*)"
                  

                   
let place_cre = Re.compile (Re_perl.re place_re)
and ia_reg_cre = Re.compile (Re_perl.re ia_reg_re)
and ia_split_cre = Re.compile (Re_perl.re ia_split_re)
and ia_filter_cre = Re.compile (Re_perl.re ia_filter_re)
and ia_filter_empty_cre = Re.compile (Re_perl.re ia_filter_empty_re)
and oa_reg_cre = Re.compile (Re_perl.re oa_reg_re)
and oa_bind_cre = Re.compile (Re_perl.re oa_bind_re)
and oa_move_fw_cre = Re.compile (Re_perl.re oa_move_fw_re)
and oa_move_bw_cre = Re.compile (Re_perl.re oa_move_bw_re)
and ext_grab_cre = Re.compile (Re_perl.re ext_grab_re)
and ext_rel_cre = Re.compile (Re_perl.re ext_rel_re)
and ext_tinit_cre = Re.compile (Re_perl.re ext_tinit_re)
                  
let rec mol_parser (s : t) : Proteine.t =
  if s = ""
  then []
  else
    try 
      if Re.execp place_cre s
      then
        let groups  = Re.exec place_cre s in
        let s' = Re.Group.get groups 1 in
        Place :: (mol_parser s')
        
      else if Re.execp ia_reg_cre s
      then
        let groups  = Re.exec ia_reg_cre s in
        let tid  = Re.Group.get groups 1
        and s' = Re.Group.get groups 2 in
        (InputArc (tid , Regular_iarc)) :: (mol_parser s')
        
      else if Re.execp ia_split_cre s
      then
        let groups  = Re.exec ia_split_cre s in
        let tid  = Re.Group.get groups 1
        and s' = Re.Group.get groups 2 in
        (InputArc (tid , Split_iarc)) :: (mol_parser s')
        
      else if Re.execp ia_filter_cre s
      then
        let groups  = Re.exec ia_filter_cre s in
        let f = Re.Group.get groups 1
        and tid  = Re.Group.get groups 2
        and s' = Re.Group.get groups 3 in
        (InputArc (tid , Filter_iarc f)) :: (mol_parser s')
        
      else if Re.execp ia_filter_empty_cre s
      then
        let groups  = Re.exec ia_filter_empty_cre s in
        let tid  = Re.Group.get groups 1
        and s' = Re.Group.get groups 2 in
        (InputArc (tid , Filter_empty_iarc)) :: (mol_parser s')
        
      else if Re.execp oa_reg_cre s
      then 
        let groups  = Re.exec oa_reg_cre s in
        let tid  = Re.Group.get groups 1
        and s' = Re.Group.get groups 2 in
        (OutputArc (tid , Regular_oarc)) :: (mol_parser s')
        
      else if Re.execp oa_bind_cre s
      then 
        let groups  = Re.exec oa_bind_cre s in
        let tid  = Re.Group.get groups 1
        and s' = Re.Group.get groups 2 in
        (OutputArc (tid , Bind_oarc)) :: (mol_parser s')
        
      else if Re.execp oa_move_fw_cre s
      then
        let groups  = Re.exec oa_move_fw_cre s in
        let tid  = Re.Group.get groups 1
        and s' = Re.Group.get groups 2 in
        (OutputArc (tid , Move_oarc true)) :: (mol_parser s')
        
      else if Re.execp oa_move_bw_cre s
      then
        let groups  = Re.exec oa_move_bw_cre s in
        let tid  = Re.Group.get groups 1
        and s' = Re.Group.get groups 2 in
        (OutputArc (tid , Move_oarc false)) :: (mol_parser s')
        
      else if Re.execp ext_grab_cre s
      then
        let groups  = Re.exec ext_grab_cre s in
        let g  = Re.Group.get groups 1
        and s' = Re.Group.get groups 2 in
        (Extension (Grab_ext g)) :: (mol_parser s')
        
      else if Re.execp ext_rel_cre s
      then
        let groups  = Re.exec ext_rel_cre s in
        let s' = Re.Group.get groups 1 in
        Extension Release_ext :: (mol_parser s')
        
      else if Re.execp ext_tinit_cre s
      then
        let groups  = Re.exec ext_tinit_cre s in
        let s' = Re.Group.get groups 1 in
        Extension Init_with_token_ext :: (mol_parser s')
        
      else 
        mol_parser (Str.string_after s 1)
                   (* if a group did not match, catch exception and continue parsing *) 
    with _ -> mol_parser (Str.string_after s 1)
            
let to_proteine (m : t) : Proteine.t = 
  mol_parser m
  
      
let rec of_proteine (p : Proteine.t) : t =
  let acid_to_mol (a : Acid_types.acid) : t = 
    match a with
    | Place  ->
       place_id 
    | InputArc (s,Regular_iarc)  ->
       ia_reg_id ^ s ^ msg_end_id
    | InputArc (s,Split_iarc) ->
       ia_split_id ^ s ^ msg_end_id 
    | InputArc (s,(Filter_iarc f))  ->
       ia_filter_id ^ f ^ s ^msg_end_id
    | InputArc (s, Filter_empty_iarc) ->
       ia_filter_empty_id ^ s ^ msg_end_id
    | OutputArc (s,Regular_oarc) ->
       oa_reg_id ^ s ^ msg_end_id
    | OutputArc (s,Bind_oarc)  ->
       oa_bind_id ^ s ^ msg_end_id
    | OutputArc (s,Move_oarc true) ->
       oa_move_fw_id ^ s^ msg_end_id
    | OutputArc (s,Move_oarc false)  ->
       oa_move_bw_id ^ s^ msg_end_id
    | Extension Release_ext  ->
       ext_rel_id 
    | Extension Init_with_token_ext  ->
       ext_tinit_id 
    | Extension (Grab_ext g) ->
       ext_grab_id ^ g ^msg_end_id
  in 
  match p with
  | a :: p' ->
     (acid_to_mol a) ^ (of_proteine p')
  | [] -> ""
