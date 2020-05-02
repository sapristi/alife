%raw
"const cytoscape = require('cytoscape'); const cola = require('cytoscape-cola'); cytoscape.use( cola )";

%raw
"const cytoscape_utils = require('./../cytoscape/cytoscape_utils')";

open Client_utils;
open Client_types;

type cytoscape_style;

type cytoscape_conf = {
  container: Dom.element,
  elements: Cytoscape_pnet.elements,
  style: cytoscape_style,
};

type cytoscape_manager = {
  update: Petri_net.petri_net => unit,
  run: unit => unit,
};
type cy_node;

type cytoscape_event_handler = {
  set_node_selected: cy_node => unit,
  set_node_unselected: unit => unit,
};

type cytoscape_manager_maker =
  (Petri_net.petri_net, Dom.element, cytoscape_event_handler) =>
  cytoscape_manager;

type cytoscape_utils = {
  pnet_style: cytoscape_style,
  make_pnet_graph: cytoscape_manager_maker,
};
[@bs.val] external make_cytoscape: cytoscape_conf => unit = "cytoscape";
[@bs.val] external cytoscape_utils: cytoscape_utils = "cytoscape_utils";

Js.log2("CY", cytoscape_utils);

[@react.component]
let make = (~selectedPnet) => {
  let containerRef: React.Ref.t(Js.Nullable.t(Dom.element)) =
    React.useRef(Js.Nullable.null);
  let (pnet, setPnet) = React.useState(() => None);
  /* let (elements, setElements) = React.useState(() => [||]); */
  Js.log2("Pnet controls", selectedPnet);
  React.useEffect1(
    () => {
      switch (selectedPnet) {
      | None => ()
      | Some((mol, pnet_id)) =>
        YaacApi.request(
          Fetch.Get,
          "/sandbox/amol/" ++ mol ++ "/pnet/" ++ pnet_id->string_of_int,
          ~json_decode=Petri_net.petri_net_decode,
          ~callback=
            res => {
              Js.log2("Res", res);
              setPnet(_ => Some(res));
            },
          (),
        )
        ->ignore
      };
      None;
    },
    [|selectedPnet|],
  );

  React.useEffect2(
    () => {
      let containerOpt = containerRef->React.Ref.current->Js.Nullable.to_opt;
      switch (pnet, containerOpt) {
      | (Some(pnet'), Some(container)) =>
        make_cytoscape({
          container,
          elements: Cytoscape_pnet.pnet_to_cytoscape_elements(pnet'),
          style: cytoscape_utils.pnet_style,
        })

      | _ => ()
      };
      None;
    },
    (pnet, containerRef->React.Ref.current),
  );

  let cyEHandler = {
    set_node_selected: n => Js.log2("Select", n),
    set_node_unselected: () => Js.log("Unselect"),
  };

  <div
    ref={ReactDOMRe.Ref.domRef(containerRef)}
    style=Css.(style([width(px(600)), height(px(300))]))
  />;
};
