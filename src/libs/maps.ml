

module MakeDoubleMultiMap = 
  functor 
  (KeyT : BatInterfaces.OrderedType) 
  (ValueT : BatInterfaces.OrderedType) -> 
struct 

  include BatMap.Make(KeyT) 
  
  module Set = BatSet.Make(ValueT)
  type set_pair = Set.t * Set.t
    
  let add_left (k : KeyT.t) (v : ValueT.t) (m : set_pair t) = 
    begin
      if mem k m
      then 
	let (l, r) = find k m in
	add k (Set.add v l, r) m
      else 
	add k (Set.singleton v, Set.empty) m
    end

  let add_right (k : KeyT.t) (v : ValueT.t) (m : set_pair t) = 
    begin
      if mem k m
      then 
	let (l, r) = find k m in
	add k (l, Set.add v r) m
      else 
	add k (Set.empty, Set.singleton v) m
    end

  let get_all_couples (k : KeyT.t) (m : set_pair t) = 
    let (l,r) = find k m in
    let rl = Set.to_list r and ll = Set.to_list l in
    Misc_library.get_all_couples ll rl
      

end;;
   


module MakeMolMap = 
  functor 
  (KeyT : BatInterfaces.OrderedType)  -> 
struct 
  include BatMap.Make(KeyT)

  let rel_change_mol_quantity (k : KeyT.t) (n : int) m =
    modify 
      k
      (fun x -> let (a,b) = x in (a+n,b))
      m


end;;
