export const pnet_to_cytoscape_elements = (pnet) => {
  const res_nodes = [];
  const res_edges = [];

  pnet.places.forEach((place, i) => {
    const place_id = `p${i}`;
    const place_node = {
      data: {
        id: place_id,
        node_type: "place",
        label: "",
      },
      classes: "place",
    };
    res_nodes.push(place_node);

    place.extensions.forEach((extension) => {
      // console.log("EXTENSION", extension)
      const [ext, ...labels_l] = extension;
      const label = labels_l.join("-");
      // const (ext, label) = Client_types.Chemistry.place_ext_to_cy(ext);
      const ext_node_id = `${place_id}_${ext}`;
      const ext_node = {
        data: {
          id: ext_node_id,
          node_type: "ext",
          label,
        },
        classes: `extension ${ext} `, // args
      };
      res_nodes.push(ext_node);

      const ext_edge = {
        data: {
          source: place_id,
          target: ext_node_id,
          directed: true,
          label: "",
        },
        classes: `extension ${ext} `, // args
      };
      res_edges.push(ext_edge);
    });
  });

  pnet.transitions.forEach((transition, i) => {
    const transition_node = {
      data: {
        id: `t${i}`,
        label: transition.id,
        node_type: `transition`,
      },
      classes: "transition",
    };
    res_nodes.push(transition_node);

    transition.input_arcs.forEach((ia) => {
      // console.log("IA", ia)
      const [ia_class, ...labels_l] = ia.iatype;
      const label = labels_l.join("-");
      const ia_edge = {
        classes: `arc ${ia_class}`,
        data: {
          source: `p${ia.source_place}`,
          target: `t${i}`,
          directed: true,
          label,
        },
      };
      res_edges.push(ia_edge);
    });

    transition.output_arcs.forEach((oa) => {
      const [oa_class, ...labels_l] = oa.oatype;
      const label = labels_l.join("-");
      const oa_edge = {
        classes: `arc ${oa_class}`,
        data: {
          source: `t${i}`,
          target: `p${oa.dest_place}`,
          directed: true,
          label,
        },
      };
      res_edges.push(oa_edge);
    });
  });
  return {
    nodes: res_nodes,
    edges: res_edges,
  };
};
