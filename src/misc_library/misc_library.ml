
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
let randomPickFromList l = 
  let n = Random.int (List.length l) in 
  List.nth l n
;;

module type EQ_TESTABLE =
  sig 
    type t
    val eq : t -> t -> bool
  end;;

module MultiSet = 
  functor (St : EQ_TESTABLE) -> 
struct
  
  let emptyMultiSet = []
    
  let rec count (x : St.t) s : int = 
    match s with
    | (e,n) :: t -> 
       if St.eq e x
	     then n 
       else count x t
    | [] -> 0
       
       
  let rec add (x : St.t) s = 
    match s with
    | (e,n) :: t -> 
       if St.eq e x 
       then (e,n+1) :: t
       else (e,n) :: add x t
    | [] -> [(x,1)]
       
       
  let rec remove (x : St.t) s = 
    match s with
    | (e,n) :: t -> 
       if St.eq e x 
       then 
	 if n = 1
	 then t
	 else (e,n-1) :: t
       else (e,n) :: remove x t
    | [] -> []
       
       
  let of_list l = 
    List.fold_right 
      (fun x s -> add x s) l []
      
end;;

