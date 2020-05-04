open Client_utils;
open Client_types;
%raw
"const cytoscape_utils = require('./../cytoscape/cytoscape_utils')";

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
let make = (~selectedPnet, ~updateSwitch, ~dispatch) => {
  let containerRef: React.Ref.t(Js.Nullable.t(Dom.element)) = React.useRef(Js.Nullable.null);
  let (pnetData, setPnetData) = React.useState(() => None);
  let (selectedNode, setSelectedNode) = React.useState(() => Cytoscape.Elements.NoNode);

  let cyEHandler = x => {
    switch (Cytoscape.Elements.node_type_decode(x)) {
    | Ok(node) => setSelectedNode(_ => node)
    | Error(e) =>
      Js.log3("Could not decode", x, e);
      setSelectedNode(_ => NoNode);
    };
  };

  let (cyWrapper, _) = React.useState(() => cytoscape_utils.setup_pnet_cy(empty_elements, cyEHandler));

  let setup_new_pnet = pnet => {
    Js.log2("Replacing with", pnet);
    cyWrapper.layout##stop();
    let newLayout = cyWrapper.replace_elements(cyWrapper.cy, Cytoscape.pnet_to_cytoscape_elements(pnet));
    cyWrapper.layout = newLayout;
    cyWrapper.update_pnet(cyWrapper.cy, pnet);
    cyWrapper.layout##run();
  };

  React.useEffect1(
    () => {
      switch (selectedPnet) {
      | None =>
        setSelectedNode(_ => NoNode);
        setPnetData(_ => None);
        cyWrapper.layout##stop();
        cyWrapper.replace_elements(cyWrapper.cy, empty_elements)->ignore;
      | Some((mol, pnet_id)) =>
        setSelectedNode(_ => NoNode);
        YaacApi.request(
          Fetch.Get,
          "/sandbox/amol/" ++ mol ++ "/pnet/" ++ pnet_id->string_of_int,
          ~json_decode=Petri_net.petri_net_decode,
          ~callback=
            res => {
              Js.log2("Res", res);
              setPnetData(_ => Some(res));
              setup_new_pnet(res);
            },
          (),
        )
        ->ignore;
      };
      None;
    },
    [|selectedPnet|],
  );

  React.useEffect1(
    () => {
      switch (selectedPnet) {
      | None => setPnetData(_ => None)
      | Some((mol, pnet_id)) =>
        YaacApi.request(
          Fetch.Get,
          "/sandbox/amol/" ++ mol ++ "/pnet/" ++ pnet_id->string_of_int,
          ~json_decode=Petri_net.petri_net_decode,
          ~callback=
            res => {
              Js.log2("Res", res);
              setPnetData(_ => Some(res));
              cyWrapper.update_pnet(cyWrapper.cy, res);
            },
          (),
        )
        ->ignore
      };
      None;
    },
    [|updateSwitch|],
  );

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

  <div className="tile">
    <div
      className="box"
      ref={ReactDOMRe.Ref.domRef(containerRef)}
      style=Css.(style([width(pct(80.)), height(px(600)), resize(vertical), overflow(hidden)]))
    />
    <div className="tile is-vertical">
      <button className="button" onClick={_ => cyWrapper.layout##stop()}>
        "Pause graph layout"->React.string
      </button>
      <button className="button" onClick={_ => cyWrapper.layout##run()}>
        "Resume graph layout"->React.string
      </button>
      {switch (pnetData, selectedNode) {
       | (None, _) => React.null
       | (Some(pnet), NPlace(i)) => <Sandbox_pnet_place pnet place_id=i />
       | (Some(pnet), NTransition(i)) => <Sandbox_pnet_transition pnet transition_id=i dispatch />
       | (_, NoNode) => React.null
       }}
    </div>
  </div>;
};
