module DoubleMultiMap = 
  functor (Ord : OrderedType) -> 
struct 
  let create = BatMap.empty
    
  let add_left k v m = 
    if mem k m
    then 
      let l, r = BatMap.find k in
      BatMap.add k (BatSet.add v l, r)
    else 
      BatMap.add k (BatSet.singleton v, BatSet.empty)


	
    
