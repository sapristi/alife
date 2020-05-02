open Client_types;

type data_node = {
  id: string,
  [@bs.as "type"]
  _type: string,
  index: option(int),
  label: option(string),
  args: list(string),
};

type data_edge = {
  /* [@bs.as "type"] */
  _type: string,
  /* label: option(string), */
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

type elements = {
  nodes: array(node),
  edges: array(edge),
};

type cy_layout = {run: unit => unit};

type cy = {
  layout: cy_layout,
  destroy: unit => unit,
};

let pnet_to_cytoscape_elements = (pnet: Petri_net.petri_net) => {
  let res_nodes = ref([]);
  let res_edges = ref([]);

  Array.iteri(
    (i, place) => {
      let place_id = "p" ++ i->string_of_int;
      let place_node: node = {
        data: {
          id: place_id,
          _type: "place",
          index: Some(i),
          label: None,
          args: [],
        },
        classes: "place",
      };
      res_nodes := [place_node, ...res_nodes^];

      List.iteri(
        (j, ext) => {
          let (ext_cy, args) = Petri_net.acid_ext_to_cy(ext);
          let ext_node: node = {
            data: {
              id: place_id ++ "_" ++ ext_cy,
              _type: ext_cy,
              args,
              index: None,
              label: None,
            },
            classes: "extension " // args
          };
          Js.log2("Ext", ext_node);
          res_nodes := [ext_node, ...res_nodes^];

          let ext_edge: edge = {
            data: {
              source: place_id,
              target: place_id ++ "_" ++ ext_cy,
              _type: ext_cy,
              directed: true,
            },
            classes: "extension " // args
          };
          res_edges := [ext_edge, ...res_edges^];
          ();
        },
        place.Petri_net.extensions,
      );
    },
    pnet.places,
  );

  Array.iteri(
    (i, transition: Petri_net.transition) => {
      let transition_node: node = {
        data: {
          id: "t" ++ i->string_of_int,
          label: Some(transition.id),
          _type: "transition",
          index: Some(i),
          args: [],
        },
        classes: "transition",
      };
      res_nodes := [transition_node, ...res_nodes^];

      List.iter(
        (ia: Petri_net.input_arc) => {
          /* Js.log2("Input arc", ia); */
          let ia_edge: edge = {
            classes: "arc",
            data: {
              source: "p" ++ ia.source_place->string_of_int,
              target: "t" ++ i->string_of_int,
              directed: true,
              _type: "",
            },
          };
          res_edges := [ia_edge, ...res_edges^];
        },
        transition.input_arcs,
      );
      List.iter(
        (oa: Petri_net.output_arc) => {
          /* Js.log2("Input arc", ia); */
          let oa_edge: edge = {
            classes: "arc",
            data: {
              source: "t" ++ i->string_of_int,
              target: "p" ++ oa.dest_place->string_of_int,
              directed: true,
              _type: "",
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
