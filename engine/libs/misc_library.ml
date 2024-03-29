open Numeric

let logger = Jlog.make_logger "Yaac.Libs.misc"

let rec cut_list l pos =
  match l with
  | [] -> ([], [])
  | h :: t ->
      if pos = 0 then ([], l)
      else
        let l1, l2 = cut_list t (pos - 1) in
        (h :: l1, l2)

let rec insert l1 pos l2 =
  if pos = 0 then l1 @ l2
  else match l1 with h :: t -> h :: insert t (pos - 1) l2 | [] -> l2

let rec append_to_rev_list l1 l2 =
  match l1 with h :: l1' -> append_to_rev_list l1' (h :: l2) | [] -> l2

let rec unzip l =
  match l with
  | (a, b) :: l' ->
      let l1, l2 = unzip l' in
      (a :: l1, b :: l2)
  | [] -> ([], [])

let rec zip l1 l2 =
  match (l1, l2) with
  | h1 :: t1, h2 :: t2 -> (h1, h2) :: zip t1 t2
  | [], [] -> []
  | _ -> failwith "zipping lists whose size don't match"

let get_all_couples (l1 : 'a list) (l2 : 'b list) : ('a * 'b) list =
  List.fold_left
    (fun (l : ('a * 'b) list) (x : 'a) ->
      List.fold_left (fun (t : ('a * 'b) list) (y : 'b) -> (x, y) :: t) l l2)
    [] l1

let common_elements l1 l2 =
  let rec common_elements_aux (l1 : (string * int) list)
      (l2 : (string * int) list) res =
    match (l1, l2) with
    | (s1, i1) :: l1', (s2, i2) :: l2' ->
        if s1 = s2 then common_elements_aux l1' l2' ((s1, i1, i2) :: res)
        else if s1 < s2 then common_elements_aux l1' l2 res
        else common_elements_aux l1 l2' res
    | _ -> res
  in
  common_elements_aux l1 l2 []

let rec pick_from_list (bound : Q.t) (c : Q.t) (value : 'a -> Q.t) (l : 'a list)
    =
  let open Q in
  match l with
  | h :: t ->
      let c' = c + value h in

      if lt bound c' then h else pick_from_list bound c' value t
  | [] -> raise Not_found

(*
let pick_from_enum (bound : float)
                   (value : 'a -> float)
                   (enum : 'a Enum.t) : 'a  =

    let c = ref 0. in
    let find_f (e : 'a) =
      c := !c +. value e;
      if !c >= bound
      then true
      else false
    in
    Enum.find find_f enum
            *)

let show_list show_e l =
  List.fold_left (fun a b -> Printf.sprintf "%s\n%s" a b) "" (List.map show_e l)

let show_list_prefix prefix show_e l =
  List.fold_left
    (fun a b -> Printf.sprintf "%s\n%s" a b)
    prefix (List.map show_e l)

let show_array_prefix prefix show_e l =
  Array.fold_left
    (fun a b -> Printf.sprintf "%s\n%s" a b)
    prefix (Array.map show_e l)

let extract_from_list l a =
  let rec aux l res =
    match l with
    | [] -> Error "not found"
    | h :: t -> if a = h then Ok (res @ t) else aux t (res @ [ h ])
  in
  aux l []

let list_files ?file_type dir =
  Sys.readdir dir |> Array.to_list
  |> List.map (Filename.concat dir)
  |> List.filter (fun x -> not (Sys.is_directory x))
  |> List.filter
       (match file_type with
       | None -> fun x -> true
       | Some suff -> fun x -> Filename.check_suffix x suff)

let printer s out () = Format.fprintf out s
