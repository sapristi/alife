(* * map with couple values *)

(* A association map (dictionary) derived from Batteries.Map where the values are a tuple. Two sets are thus linked together by a key. *)

module MakeDoubleMultiMap = 
  functor 
  (KeyT : BatInterfaces.OrderedType) 
  (ValueT : BatInterfaces.OrderedType) -> 
struct 

  include BatMap.Make(KeyT) 
  
  module Set = BatSet.Make(ValueT)
  type set_pair = Set.t * Set.t
    
  let add_left (key : KeyT.t) (value : ValueT.t) (map : set_pair t) = 
    begin
      if mem key map
      then 
        let (l, r) = find key map in
        add key (Set.add value l, r) map
      else 
        add key (Set.singleton value, Set.empty) map
    end

  let add_right (key : KeyT.t) (value : ValueT.t) (map : set_pair t) = 
    begin
      if mem key map
      then 
        let (l, r) = find key map in
        add key (l, Set.add value r) map
      else 
        add key (Set.empty, Set.singleton value) map
    end

  let get_all_couples (key : KeyT.t) (map : set_pair t) = 
    let (l,r) = find key map in
    let rl = Set.to_list r and ll = Set.to_list l in
    Misc_library.get_all_couples ll rl
      

end;;
   


module MakeMolMap = 
  functor 
  (KeyT : BatInterfaces.OrderedType)  -> 
struct 
  include BatMap.Make(KeyT)

  let rel_change_mol_quantity (key : KeyT.t) (n : int) map =
    modify 
      key
      (fun x -> let (a,b) = x in (a+n,b))
      map


end;;

  

let get_maps_keys (map : ('a, 'b) BatMultiPMap.t) : 'a list =
  BatMultiPMap.foldi
    (fun  v k keys -> k :: keys)
    map
    []
;;


