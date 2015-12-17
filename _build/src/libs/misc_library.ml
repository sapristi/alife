

let rec cut_list l pos =
  match l with
  | [] -> [], []
  | h :: t -> 
     if pos = 0
     then [],l
     else 
       let l1, l2 = (cut_list t (pos -1)) in 
       h :: l1, l2
;;


let rec insert l1 pos l2 = 
  if pos = 0 
  then l1 @ l2 
  else 
    match l1 with
    | h :: t -> h :: insert t (pos-1) l2
    | [] ->  l2
;;



let rec unzip l = 
  match l with
  | (a,b) :: l' -> 
     let l1, l2 = unzip l' in
     a::l1, b::l2
  | [] -> [], []
;;

let rec zip l1 l2 = 
  match l1, l2 with
  | h1 :: t1, h2 :: t2 -> (h1, h2) :: zip t1 t2
  | [], [] -> []
  | _ -> failwith "zipping list whose size don't match"
;;


Random.init;;
let random_pick_from_list l = 
  let n = Random.int (List.length l) in 
  List.nth l n
;;

let random_pick_from_PSet s = 
  let size = BatSet.PSet.cardinal s in
  let n = Random.int size in
  BatSet.PSet.at_rank_exn n s



let get_all_couples 
    (l1 : 'a list) 
    (l2 : 'b list) 
    : ('a * 'b) list
    = 
  
  List.fold_left 
    (fun 
      (l :  ('a * 'b) list)
      (x : 'a) -> 
	List.fold_left
	  (fun 
	    (t :  ('a * 'b) list)
	    (y : 'b) 
	  -> (x,y) :: t)
	  l
	  l2)
    []
    l1
