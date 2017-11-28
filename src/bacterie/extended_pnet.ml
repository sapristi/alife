open Graph

module Pnet_graph = Imperative.Graph.AbstractLabeled
                        (struct type t = Molecule.t end)
                        (struct type t = (Molecule.t * int) * (Molecule.t*int)
                                let default = ("",0),("",0)
                                let compare = Pervasives.compare end)
                                 

type t = {
    mols : Pnet_graph.t;
    transitions : Transition.t array;
    places : Place.t array;
    binders_book : (string * int * Pnet_graph.V.t) list;
  }
    
(* let make_from_pnet (pnet : Petri_net.t) : t = *)
  
