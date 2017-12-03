open Graph
open Batteries
   
module Pnet_graph = Imperative.Graph.AbstractLabeled
                      (struct type t = Petri_net.t
                              let compare =
                                fun p1 p2 ->
                                Pervasives.compare
                                  p1.Petri_net.uid  p2.Petri_net.uid
                       end)
                      (* a label is (place1, place2)
                         where place1 is the index of the place
                         in the node with lower uid, 
                         and place2 is the index of the place 
                         in the node with higher uid
                       *)
                      (struct type t = (int) * (int)
                              let default = 0,0
                              let compare = Pervasives.compare end)
                  
module Pnet_graph_ops = Oper.I (Pnet_graph)
module Pnet_graph_path = Path.Check (Pnet_graph)
module Pnet_graph_components = Components.Make (Pnet_graph)
                             
module Binders_map_old = BatMap.Make (struct type t = string
                                         let compare = Pervasives.compare end)

type t = {
    graph : Pnet_graph.t;
    mutable binders_map :  (string,  (Pnet_graph.V.t* int)) MultiPMap.t;
    path_checker : Pnet_graph_path.path_checker;
  }
       
let get_pnet (v : Pnet_graph.V.t) : Petri_net.t =
  (Pnet_graph.V.label v)

let binders_map_values_compare = fun (v1,n1) (v2,n2) ->
  let id1 = (get_pnet v1).uid
  and id2 = (get_pnet v2).uid
  in Pervasives.compare (id1, n1) (id2, n2)
  
let add_binders_to_map
      (vertex : Pnet_graph.V.t)
      (binders_map : (string,  (Pnet_graph.V.t* int)) MultiPMap.t)
    : (string,  (Pnet_graph.V.t* int)) MultiPMap.t =

  let binders : (int*string) list = (get_pnet vertex).binders in
  List.fold_left
    (fun map (pid, bind_patt) -> 
      MultiPMap.add bind_patt (vertex, pid) map)
    binders_map
    binders

  
(* ajoute les bindings de map2 à map1 *)
let map_union map1 map2 =
  MultiPMap.foldi
    (fun key set2 map1 ->
      MultiPMap.modify_opt
        key
        (fun oset1 ->
          match oset1 with
          | Some set1 -> Some (BatSet.PSet.union set1 set2)
          | None -> Some set2
        )  map1)
    map2
    map1

let remove_from_map
      (map : (string, (Pnet_graph.V.t * int)) MultiPMap.t)
      (v : Pnet_graph.V.t) =
  MultiPMap.map
    (fun set -> BatSet.PSet.filter
                  (fun (v',_) -> v = v') set)
    (fun _ -> binders_map_values_compare)
    map

  
                                                         
let make_from_pnet (pnet : Petri_net.t) : t =
  let this_vertex = Pnet_graph.V.create pnet in
  let graph = Pnet_graph.create() in
  Pnet_graph.add_vertex graph (this_vertex);
  let binders_map = add_binders_to_map
                      this_vertex
                      (MultiPMap.create
                         String.compare
                         binders_map_values_compare) in
  let path_checker = Pnet_graph_path.create graph
                  
  in {graph;binders_map;path_checker}

          
let bind (epnet1: t) (pos1 : (Pnet_graph.V.t * int))
         (epnet2: t) (pos2 : (Pnet_graph.V.t * int))
    : t =

  let (v1, i1) = pos1 and (v2, i2) = pos2 in 
  let new_graph = Pnet_graph_ops.union epnet1.graph epnet2.graph in
  let new_edge =
    if (get_pnet v1).uid < (get_pnet v2).uid
    then Pnet_graph.E.create v1 (i1, i2) v2
    else if (get_pnet v1).uid = (get_pnet v2).uid
    then failwith "extended_pnet : making cycling edge"
    else Pnet_graph.E.create v2 (i2, i1) v1
  in 
                     
  Pnet_graph.add_edge_e new_graph new_edge;
  {graph = new_graph;
   binders_map = map_union epnet1.binders_map epnet2.binders_map;
   path_checker = Pnet_graph_path.create new_graph}

  
let possible_binds (epnet1 : t) (epnet2 : t) :
      ((Pnet_graph.V.t * int) Set.PSet.t
       * (Pnet_graph.V.t * int) Set.PSet.t) list =
  
  MultiPMap.foldi
    (fun
       (bind_patt1 : string)
       (set1 :  (Pnet_graph.V.t * int) Set.PSet.t)
       (res : ((Pnet_graph.V.t * int) Set.PSet.t
               * (Pnet_graph.V.t * int) Set.PSet.t) list) ->
      
      (MultiPMap.foldi
         (fun (bind_patt2 : string)
              (set2 : (Pnet_graph.V.t * int) Set.PSet.t)
              (res : ((Pnet_graph.V.t * int) Set.PSet.t
                      * (Pnet_graph.V.t * int) Set.PSet.t) list) ->
           
           if bind_patt1 = (String.rev bind_patt2)
           then (set1, set2) :: res
           else res
         )
         epnet2.binders_map []) @ res)
  
    epnet1.binders_map []
;;


let sub_graph (epnet : t) (vertices_l : Pnet_graph.V.t list) : t =
  let vertices = Array.of_list vertices_l in
  let v_num = Array.length vertices in

  let new_graph = Pnet_graph.create ~size:v_num () in

  Array.iter (fun v -> Pnet_graph.add_vertex new_graph v) vertices;
  
  for i = 0 to v_num -1 do
    for j = 0 to i-1 do
      let edges = Pnet_graph.find_all_edges
                    epnet.graph
                    vertices.(i)
                    vertices.(j)
      in
      List.iter (fun e -> Pnet_graph.add_edge_e new_graph e) edges; 
    done
  done;
  let new_binders =
    MultiPMap.map
      (fun set -> BatSet.PSet.filter
                    (fun (v,_) -> Array.mem v vertices) set)
      (fun _ -> binders_map_values_compare)
      epnet.binders_map
  and path_checker = Pnet_graph_path.create new_graph in

  {graph=new_graph;binders_map=new_binders;path_checker}
  
  
let unbind (epnet : t)
           ((v1, ind1) : (Pnet_graph.V.t * int))
           ((v2, ind2) : (Pnet_graph.V.t * int))
  =
  (* we have to reorder the arguments *)
  let (v1, v2, ind1, ind2) =
    if (get_pnet v1).uid < (get_pnet v2).uid
    then v1, v2, ind1, ind2
    else if (get_pnet v1).uid = (get_pnet v2).uid
    then failwith "extended_pnet : cycling edge"
    else v2, v1, ind2, ind1
  in

  (* then remove the edge *)
  let edge = Pnet_graph.E.create v1 (ind1, ind2) v2
  in
  (* the test is not necessary but could 
     disclose some bugs *)
  if Pnet_graph.mem_edge_e epnet.graph edge
  then Pnet_graph.remove_edge_e epnet.graph edge
  else failwith "extended_pnet : removing absent edge";
  
  (* and finally test if the graph is still connex *)
  if Pnet_graph_path.check_path
       epnet.path_checker
       v1 v2
  then 
    None
  else
    Some
      (List.map
         (fun vertices -> sub_graph epnet vertices)
         (Pnet_graph_components.scc_list epnet.graph))
