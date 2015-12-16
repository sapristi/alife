

module MakeDoubleMultiMap 
  (KeyT : BatInterfaces.OrderedType) 
  (ValueT : BatInterfaces.OrderedType) = 
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
end;;
   


module MakeMolMap
  (KeyT : BatInterfaces.OrderedType)  = 
struct 
  include BatMap.Make(KeyT)

  let increase_mol_quantity (k : KeyT.t) (n : int) m =
    modify 
      k
      (fun x -> let (a,b) = x in (a+n,b))
      m


end;;
