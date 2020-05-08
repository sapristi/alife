%raw
"const cytoscape = require('cytoscape'); const cola = require('cytoscape-cola'); cytoscape.use( cola )";

open Types;

module Elements = {
  [@decco]
  type node_type =
    | NPlace(int)
    | NTransition(int)
    | NoNode;

  type data_node = {
    id: string,
    label: string,
    node_type: Js.Json.t,
  };

  type data_edge = {
    label: string,
    source: string,
    target: string,
    directed: bool,
  };

  type node = {
    data: data_node,
    classes: string,
  };
  type edge = {
    data: data_edge,
    classes: string,
  };

  type t = {
    nodes: array(node),
    edges: array(edge),
  };
};

type style;

[@bs.deriving abstract]
type cytoscape_conf = {
  [@bs.optional]
  container: Dom.element,
  [@bs.optional]
  elements: Elements.t,
  [@bs.optional]
  style,
};

type cytoscape_manager = {
  update: Types.Petri_net.t => unit,
  run: unit => unit,
};
type cy_node;

type cytoscape_event_handler = {
  set_node_selected: cy_node => unit,
  set_node_unselected: unit => unit,
};

type cytoscape_manager_maker = (Types.Petri_net.t, Dom.element, cytoscape_event_handler) => cytoscape_manager;

type layout_conf;
type layout = {
  .
  [@bs.meth] "run": unit => unit,
  [@bs.meth] "stop": unit => unit,
};

type cy = {
  .
  [@bs.meth] "layout": layout_conf => layout,
  [@bs.meth] "destroy": unit => unit,
  [@bs.meth] "mount": Dom.element => unit,
  [@bs.meth] "unmount": unit => unit,
};

[@bs.module] external cytoscape: cytoscape_conf => cy = "cytoscape";

let pnet_to_cytoscape_elements = (pnet: Types.Petri_net.t): Elements.t => {
  let res_nodes = ref([]);
  let res_edges = ref([]);

  Array.iteri(
    (i, place: Place.t) => {
      let place_id = "p" ++ i->string_of_int;
      let place_node: Elements.node = {
        data: {
          id: place_id,
          node_type: Elements.node_type_encode(NPlace(i)),
          label: "",
        },
        classes: "place",
      };
      res_nodes := [place_node, ...res_nodes^];

      List.iteri(
        (j, ext) => {
          let (ext, label) = Client_types.place_ext_to_cy(ext);
          let ext_node_id = place_id ++ "_" ++ ext;
          let ext_node: Elements.node = {
            data: {
              id: ext_node_id,
              node_type: Elements.node_type_encode(NoNode),
              label,
            },
            classes: "extension " ++ ext // args
          };
          res_nodes := [ext_node, ...res_nodes^];

          let ext_edge: Elements.edge = {
            data: {
              source: place_id,
              target: ext_node_id,
              directed: true,
              label: "",
            },
            classes: "extension " ++ ext // args
          };
          res_edges := [ext_edge, ...res_edges^];
          ();
        },
        place.extensions,
      );
    },
    pnet.places,
  );

  Array.iteri(
    (i, transition: Transition.t) => {
      let transition_node: Elements.node = {
        data: {
          id: "t" ++ i->string_of_int,
          label: transition.id,
          node_type: Elements.node_type_encode(NTransition(i)),
        },
        classes: "transition",
      };
      res_nodes := [transition_node, ...res_nodes^];

      List.iter(
        (ia: Transition.input_arc) => {
          let (ia_class, label) = Client_types.input_arc_to_cy(ia.iatype);
          let ia_edge: Elements.edge = {
            classes: "arc " ++ ia_class,
            data: {
              source: "p" ++ ia.source_place->string_of_int,
              target: "t" ++ i->string_of_int,
              directed: true,
              label,
            },
          };
          res_edges := [ia_edge, ...res_edges^];
        },
        transition.input_arcs,
      );
      List.iter(
        (oa: Transition.output_arc) => {
          /* Js.log2("Input arc", ia); */
          let (oa_class, label) = Client_types.output_arc_to_cy(oa.oatype);
          let oa_edge: Elements.edge = {
            classes: "arc " ++ oa_class,
            data: {
              source: "t" ++ i->string_of_int,
              target: "p" ++ oa.dest_place->string_of_int,
              directed: true,
              label,
            },
          };
          res_edges := [oa_edge, ...res_edges^];
        },
        transition.output_arcs,
      );
    },
    /* List.iter(oa => {Js.log2("output arc", oa)}, transition.output_arcs); */
    pnet.transitions,
  );

  {nodes: Array.of_list(res_nodes^), edges: Array.of_list(res_edges^)};
};
