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
