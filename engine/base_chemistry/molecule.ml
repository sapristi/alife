(* * this file *)

(*   proteine.ml defines the basic properties of a proteine, some *)
(*   functions to help build a petri-net out of it and a module to help it *)
(*   get managed by a petri-net (i.e. simulate chemical reactions *)

open Easy_logging_yojson
include Types.Molecule

let logger = Logging.get_logger "Yaac.Base_chem.Molecule"

let check mol =
  if String.length mol = 0 then (
    logger#info "Bad molecule: empty";
    false)
  else true

let atoms = "[A-F]"

let place_id = "AAA"
and ia_reg_id = "BAA"
and ia_split_id = "BBA"
and ia_filter_id = "BC"
and ia_filter_empty_id = "BAB"
and ia_no_token_id = "BAC"
and oa_reg_id = "CAA"
and oa_merge_id = "CBA"
and oa_move_fw_id = "CCA"
and oa_move_bw_id = "CCB"
and ext_grab_id = "ABA"
and ext_rel_id = "ABB"
and ext_tinit_id = "ABC"
and ext_bind_id = "ACC"
(*TODO: change to DDB ? otherwise it's the only place where F is used *)

and msg_end_id = "DDF"

let place_re = place_id
and ia_reg_re = ia_reg_id ^ "(.*?)" ^ msg_end_id
and ia_split_re = ia_split_id ^ "(.*?)" ^ msg_end_id
and ia_filter_re = ia_filter_id ^ "(" ^ atoms ^ ")(.*?)" ^ msg_end_id
and ia_filter_empty_re = ia_filter_empty_id ^ "(.*?)" ^ msg_end_id
and ia_no_token_re = ia_no_token_id ^ "(.*?)" ^ msg_end_id
and oa_reg_re = oa_reg_id ^ "(.*?)" ^ msg_end_id
and oa_merge_re = oa_merge_id ^ "(.*?)" ^ msg_end_id
and oa_move_fw_re = oa_move_fw_id ^ "(.*?)" ^ msg_end_id
and oa_move_bw_re = oa_move_bw_id ^ "(.*?)" ^ msg_end_id
and ext_grab_re = ext_grab_id ^ "(.*?)" ^ msg_end_id
and ext_rel_re = ext_rel_id
and ext_tinit_re = ext_tinit_id
and ext_bind_re = ext_bind_id ^ "(.*?)" ^ msg_end_id

let parsers : (string * (Re.Group.t -> Types.Acid.acid * string)) list =
  [
    ( place_re,
      fun groups ->
        let s' = Re.Group.get groups 1 in
        (Place, s') );
    ( ia_reg_re,
      fun groups ->
        let tid = Re.Group.get groups 1 and s' = Re.Group.get groups 2 in
        (InputArc (tid, Regular_iarc), s') );
    ( ia_split_re,
      fun groups ->
        let tid = Re.Group.get groups 1 and s' = Re.Group.get groups 2 in
        (InputArc (tid, Split_iarc), s') );
    ( ia_filter_re,
      fun groups ->
        let f = Re.Group.get groups 1
        and tid = Re.Group.get groups 2
        and s' = Re.Group.get groups 3 in
        (InputArc (tid, Filter_iarc f), s') );
    ( ia_filter_empty_re,
      fun groups ->
        let tid = Re.Group.get groups 1 and s' = Re.Group.get groups 2 in
        (InputArc (tid, Filter_empty_iarc), s') );
    ( ia_no_token_re,
      fun groups ->
        let tid = Re.Group.get groups 1 and s' = Re.Group.get groups 2 in
        (InputArc (tid, No_token_iarc), s') );
    ( oa_reg_re,
      fun groups ->
        let tid = Re.Group.get groups 1 and s' = Re.Group.get groups 2 in
        (OutputArc (tid, Regular_oarc), s') );
    ( oa_merge_re,
      fun groups ->
        let tid = Re.Group.get groups 1 and s' = Re.Group.get groups 2 in
        (OutputArc (tid, Merge_oarc), s') );
    ( oa_move_fw_re,
      fun groups ->
        let tid = Re.Group.get groups 1 and s' = Re.Group.get groups 2 in
        (OutputArc (tid, Move_oarc true), s') );
    ( oa_move_bw_re,
      fun groups ->
        let tid = Re.Group.get groups 1 and s' = Re.Group.get groups 2 in
        (OutputArc (tid, Move_oarc false), s') );
    ( ext_grab_re,
      fun groups ->
        let g = Re.Group.get groups 1 and s' = Re.Group.get groups 2 in
        (Extension (Grab_ext g), s') );
    ( ext_rel_re,
      fun groups ->
        let s' = Re.Group.get groups 1 in
        (Extension Release_ext, s') );
    ( ext_tinit_re,
      fun groups ->
        let s' = Re.Group.get groups 1 in
        (Extension Init_with_token_ext, s') );
  ]

let compiled_parsers =
  List.map
    (fun (re, v) -> (Re.compile (Re.Perl.re ("^" ^ re ^ "(.*)")), v))
    parsers

let rec apply_parsers parsers mol =
  match parsers with
  | [] -> (None, Str.string_after mol 1)
  | (cre, parser_fun) :: parsers' -> (
      match Re.exec_opt cre mol with
      | None -> apply_parsers parsers' mol
      | Some groups ->
          let acid, mol' = parser_fun groups in
          (Some acid, mol'))

let%expect_test _ =
  let Some a, remainder = apply_parsers compiled_parsers "AAA" in
  print_endline (Types.Acid.show_acid a);
  print_endline remainder;
  [%expect {|Type_acid.Place|}]

let%expect_test _ =
  let Some a, remainder = apply_parsers compiled_parsers "BAAADDF" in
  print_endline (Types.Acid.show_acid a);
  print_endline remainder;
  [%expect {|(Type_acid.InputArc ("A", Type_acid.Regular_iarc))|}]

let rec mol_parser_aux res (mol : string) : Proteine.t =
  if mol = "" then List.rev res
  else
    match apply_parsers compiled_parsers mol with
    | None, mol' -> mol_parser_aux res mol'
    | Some acid, mol' -> mol_parser_aux (acid :: res) mol'

let mol_parser = mol_parser_aux []

let to_proteine (m : string) : Proteine.t =
  let res = mol_parser m in
  logger#debug "Parsed %s to:\n%s" m (Proteine.show res);
  res

let rec of_proteine (p : Proteine.t) : string =
  let acid_to_mol (a : Types.Acid.acid) : string =
    match a with
    | Place -> place_id
    | InputArc (s, Regular_iarc) -> ia_reg_id ^ s ^ msg_end_id
    | InputArc (s, Split_iarc) -> ia_split_id ^ s ^ msg_end_id
    | InputArc (s, Filter_iarc f) -> ia_filter_id ^ f ^ s ^ msg_end_id
    | InputArc (s, Filter_empty_iarc) -> ia_filter_empty_id ^ s ^ msg_end_id
    | InputArc (s, No_token_iarc) -> ia_no_token_id ^ s ^ msg_end_id
    | OutputArc (s, Regular_oarc) -> oa_reg_id ^ s ^ msg_end_id
    | OutputArc (s, Merge_oarc) -> oa_merge_id ^ s ^ msg_end_id
    | OutputArc (s, Move_oarc true) -> oa_move_fw_id ^ s ^ msg_end_id
    | OutputArc (s, Move_oarc false) -> oa_move_bw_id ^ s ^ msg_end_id
    | Extension Release_ext -> ext_rel_id
    | Extension Init_with_token_ext -> ext_tinit_id
    | Extension (Grab_ext g) -> ext_grab_id ^ g ^ msg_end_id
  in
  match p with a :: p' -> acid_to_mol a ^ of_proteine p' | [] -> ""
