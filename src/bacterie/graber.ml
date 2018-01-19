
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
type t =
  {mol_repr : string;
   str_repr : string;
   re : Re.re}
  [@@deriving show]

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
                
let grab_location_cre = Re.compile (Re_perl.re grab_location_re)
and wildcard_cre = Re.compile (Re_perl.re wildcard_re)
                 
let make (m : string)  =
  try 
    if Re.execp grab_location_cre m
    then
      let rep_loc (g : Re.Group.t) : string =
        Re.Group.get g 1 ^ "(" ^ Re.Group.get g 2 ^ ")"
      in
      let m1 = Re.replace ~all:false
                          grab_location_cre
                          ~f:rep_loc m in
      let m2 = Re.replace_string wildcard_cre
                                 ~by:".*?" m1
      in
      let m3 = "^"^m2^"$" in
      Some {mol_repr=m;
            str_repr=m2;
            re = Re.compile (Re_perl.re m3)}
    else
      None
  with
  | _ -> None
       
let get_match_pos (graber : t)  (mol : string) : int option =
  if Re.execp graber.re mol
  then 
    let g = Re.exec graber.re mol in
    Some (Re.Group.start g 1)
  else
    None
  
let to_yojson (g :t) : Yojson.Safe.json =
  `String g.mol_repr
  
let of_yojson (json : Yojson.Safe.json) : (t,string) result =
  match json with
  | `String s ->
     (
       match make s with
       | Some g -> Ok g
       | None -> Error "graber : cannot build from json"
     )
  | _ -> Error "graber : cannot build from json"
       
