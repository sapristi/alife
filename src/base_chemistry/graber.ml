open Easy_logging_yojson

let logger = Logging.get_logger "Yaac.Base_chem.Graber"
(* * Graber *)

(* This file implements the graber, which allows a proteine to grab *)
(* a molecule by recognizing a regexp on his sequence of atoms *)

(* Here are the allowed commands : *)
(*  + atom : a specified atom *)
(*  + anything : any string of atoms, length > 0 *)
(*  + grab : the grab position *)
(*  + or : between two atoms, or combinator -> plus tard *)

(* Il y a plusieurs choix : *)
(*  + soit on interprète certaines séquences comme des commandes *)
(*    spéciales, et le reste comme de atomes (ce qui limite *)
(*    les séquences qu'on peut reconnaître) *)
(*  + soit on insère aussi un marqueur pour les atomes (à la *)
(*    manière du symbole d'échappement \ pour les caractères *)
(*    spéciaux) *)

(* *** graber type *)
include Chemistry_types.Types.Graber

(* *** build_from_atom_list *)
(*     Transforms a list of atoms into a string representing a regular *)
(*     expression. *)

(*     Special expressions  *)
(*      + an atome surrounded by two F atoms :  *)
(*        the grabing point, that is the place at which the grabed *)
(*        molecule will be split *)

(*      + two F atoms : *)
(*        any non-empty sequence of atoms *)

let grab_location_re = "(.*?)F(.)F"
and wildcard_re = "FF"

let grab_location_cre = Re.compile (Re.Perl.re grab_location_re)
and wildcard_cre = Re.compile (Re.Perl.re wildcard_re)

let make (m : string)  =
  try
    if Re.execp grab_location_cre m
    then
      let rep_loc (g : Re.Group.t) : string =
        Re.Group.get g 1 ^ "(" ^ Re.Group.get g 2 ^ ")"
      in
      let mol_repr = Re.replace ~all:false
                          grab_location_cre
                          ~f:rep_loc m in
      let str_repr' = Re.replace_string wildcard_cre
          ~by:".*?" mol_repr
      in let str_repr = "^" ^ str_repr'
      in
      logger#debug "Compiled %s\nfrom %s" str_repr m;
      Some {mol_repr;
            str_repr;}
    else
      None
  with
  | _ -> None

module Re_store = struct
  module M = Map.Make(String)

  let m = ref M.empty

  let get s  = match M.find_opt s (!m) with
    | Some r -> r
    | None ->
      let r = Re.compile (Re.Perl.re s) in
      m := (M.add s r (!m));
      r
end


let get_match_pos (graber : t)  (mol : string) : int option =
  logger#debug "Get match for graber:%s\n with mol: %s" graber.str_repr mol;
  let re = Re_store.get graber.str_repr in

  if Re.execp re mol
  then
    let g = Re.exec re mol in
    logger#debug "Match pos: %i" (Re.Group.start g 1);
    Some (Re.Group.start g 1)
  else
    (
      logger#debug "no match pos";
      None
    )
