open Graph
open Batteries
   
module Pnet_graph = Imperative.Graph.AbstractLabeled
                      (struct type t = Petri_net.t
                              let compare =
                                fun p1 p2 ->
                                Pervasives.compare
                                  p1.Petri_net.uid  p2.Petri_net.uid
                       end)
                      (* a label is (src_place, dst_place)
                         where src_place is the index of the place
                         in the source node, and the same for dst_place
                       *)
                      (struct type t = (int) * (int)
                              let default = (0),(0)
                              let compare = Pervasives.compare end)
                  
module Pnet_graph_ops = Oper.I (Pnet_graph)

module Binders_map = BatMap.Make (struct type t = int
                                         let compare = Pervasives.compare end)
type t = Pnet_graph.t

let get_pnet (v : Pnet_graph.V.t) : Petri_net.t =
  (Pnet_graph.V.label v)
       
let make_from_pnet (pnet : Petri_net.t) : t =
  let this_vertex = Pnet_graph.V.create pnet in
  let pnets = Pnet_graph.create() in
  Pnet_graph.add_vertex pnets (this_vertex);
  pnets

let bind (epnet1: t) (pos1 : (Pnet_graph.V.t * int))
         (epnet2: t) (pos2 : (Pnet_graph.V.t * int))
    : t =

  let (v1, i1) = pos1 and (v2, i2) = pos2 in 
  let new_epnet = Pnet_graph_ops.union epnet1 epnet2 in
  let new_edge = Pnet_graph.E.create v1 (i1, i2) v2 in 
                     
  Pnet_graph.add_edge_e new_epnet new_edge;
  new_epnet
  
  
let possible_binds (epnet1 : t) (epnet2 : t) :
      ((Pnet_graph.V.t * int)
       * (Pnet_graph.V.t * int)) list =

  (* oui c'est un peu sale *)

  Pnet_graph.fold_vertex
    (fun vertex res ->
      (List.fold_left
         (fun res (index, binder) ->
           (Pnet_graph.fold_vertex
              (fun vertex' res ->
                if (get_pnet vertex).uid != (get_pnet vertex').uid
                then 
                  (List.map
                     (fun index' -> (vertex,index),(vertex', index'))
                            (Petri_net.matching_binders
                               binder
                               (get_pnet vertex')))@res
                else res) epnet2 [])@res
        ) [] (get_pnet vertex).binders)@res
    )  epnet1 []
  
  
  
let self_possible_bins (epnet : t) : 
      ((Pnet_graph.V.t * int)
       * (Pnet_graph.V.t * int)) list =      
  

  Pnet_graph.fold_vertex
    (fun vertex res ->
      (List.fold_left
         (fun res (index, binder) ->
           (Pnet_graph.fold_vertex
              (fun vertex' res ->
                if (get_pnet vertex).uid != (get_pnet vertex').uid
                then
                  let d = 
                  
                  (List.map
                     (fun index' -> (vertex,index),(vertex', index'))
                            (Petri_net.matching_binders
                               binder
                               (get_pnet vertex')))@res
                else res) epnet [])@res
        ) [] (get_pnet vertex).binders)@res
    )  epnet []
