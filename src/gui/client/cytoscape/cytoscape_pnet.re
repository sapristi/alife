%raw
"const cytoscape_utils = require('./../cytoscape/cytoscape_utils')";
open Client_types;

type event_handler = Js.Json.t => unit;

type pnet_cytoscape_wrapper = {
  cy: Cytoscape.cy,
  mutable layout: Cytoscape.layout,
  update_pnet: (Cytoscape.cy, Petri_net.petri_net) => unit,
  replace_elements: (Cytoscape.cy, Cytoscape.Elements.t) => Cytoscape.layout,
};

type cytoscape_utils = {
  pnet_style: Cytoscape.style,
  cola_layout_conf: Cytoscape.layout_conf,
  setup_pnet_cy: (Cytoscape.Elements.t, event_handler) => pnet_cytoscape_wrapper,
};
let empty_elements = {Cytoscape.Elements.nodes: [||], edges: [||]};
[@bs.val] external cytoscape_utils: cytoscape_utils = "cytoscape_utils";

[@react.component]
let make = (~pnet, ~styles, ~cyEHandler) => {
  let containerRef: React.Ref.t(Js.Nullable.t(Dom.element)) = React.useRef(Js.Nullable.null);
  let (cyWrapper, _) = React.useState(() => cytoscape_utils.setup_pnet_cy(empty_elements, cyEHandler));

  React.useEffect1(
    () => {
      let containerOpt = containerRef->React.Ref.current->Js.Nullable.to_opt;
      switch (containerOpt) {
      | Some(container) => cyWrapper.cy##mount(container)
      | None => cyWrapper.cy##unmount()
      };
      None;
    },
    [|containerRef->React.Ref.current|],
  );

  let setup_new_pnet = pnet => {
    Js.log2("Replacing with", pnet);
    cyWrapper.layout##stop();
    let newLayout = cyWrapper.replace_elements(cyWrapper.cy, Cytoscape.pnet_to_cytoscape_elements(pnet));
    cyWrapper.layout = newLayout;
    cyWrapper.update_pnet(cyWrapper.cy, pnet);
    cyWrapper.layout##run();
  };

  <div
    className="box"
    ref={ReactDOMRe.Ref.domRef(containerRef)}
    style=Css.(style([resize(vertical), overflow(hidden), ...styles]))
  />;
};
