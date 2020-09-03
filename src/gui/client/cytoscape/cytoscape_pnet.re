%raw
"const cytoscape_utils = require('./../cytoscape/cytoscape_utils')";
open Components;
type event_handler = Js.Json.t => unit;

type pnet_cytoscape_wrapper = {
  cy: Cytoscape.cy,
  mutable layout: Cytoscape.layout,
  update_pnet: (Cytoscape.cy, Types.Petri_net.t) => unit,
  replace_elements: (Cytoscape.cy, Cytoscape.Elements.t) => Cytoscape.layout,
};

type cytoscape_utils = {
  pnet_style: Cytoscape.style,
  cola_layout_conf: Cytoscape.layout_conf,
  setup_pnet_cy:
    (Cytoscape.Elements.t, event_handler) => pnet_cytoscape_wrapper,
};
let empty_elements = {Cytoscape.Elements.nodes: [||], edges: [||]};
[@bs.val] external cytoscape_utils: cytoscape_utils = "cytoscape_utils";

[@react.component]
let make =
    (
      ~pnetIdO: option(int),
      ~pnetO,
      ~styles=[],
      ~cyEHandler,
      ~collapsable=false,
      ~pxHeight,
    ) => {
  let containerRef: React.ref(Js.Nullable.t(Dom.element)) =
    React.useRef(Js.Nullable.null);
  let (cyWrapper, _) =
    React.useState(() =>
      cytoscape_utils.setup_pnet_cy(empty_elements, cyEHandler)
    );
  let (previous_pnetIdO, setPrevious_pnetIdO) = React.useState(() => None);

  React.useEffect1(
    () => {
      let containerOpt = containerRef.current->Js.Nullable.toOption;
      switch (containerOpt) {
      | Some(container) => cyWrapper.cy##mount(container)
      | None => cyWrapper.cy##unmount()
      };
      None;
    },
    [|containerRef.current|],
  );

  let setup_new_pnet = pnetO => {
    Js.log2("Replacing with", pnetO);
    cyWrapper.layout##stop();
    switch (pnetO) {
    | None =>
      Js.log("Cytoscape clear");
      cyWrapper.replace_elements(cyWrapper.cy, empty_elements)->ignore;
    /* cyWrapper.cy##destroy(); */
    | Some(pnet) =>
      Js.log("Cytoscape new layout");
      let newLayout =
        cyWrapper.replace_elements(
          cyWrapper.cy,
          Cytoscape.pnet_to_cytoscape_elements(pnet),
        );
      cyWrapper.layout = newLayout;
      cyWrapper.update_pnet(cyWrapper.cy, pnet);
      cyWrapper.layout##run();
    };
  };

  React.useEffect2(
    () => {
      Js.log4("Cytoscape: pnet_id", previous_pnetIdO, "->", pnetIdO);
      switch (previous_pnetIdO, pnetIdO, pnetO) {
      | (Some(id), Some(id'), Some(pnet)) =>
        if (id === id') {
          Js.log("Update pnet");
          cyWrapper.update_pnet(cyWrapper.cy, pnet);
        } else {
          Js.log("Set new pnet");
          setup_new_pnet(pnetO);
          setPrevious_pnetIdO(_ => Some(id'));
        }
      | (_, _, None) => setup_new_pnet(None)
      | (_, id, _) =>
        setup_new_pnet(pnetO);
        setPrevious_pnetIdO(_ => id);
      };
      None;
    },
    (pnetIdO, pnetO),
  );
  <Panel collapsable styles>
    (
      <HFlex
        style=Css.[
          alignItems(center),
          justifyContent(spaceBetween),
          width(pct(100.)),
        ]>
        "Petri Net"->React.string
        <HFlex>
          <ButtonIcon onClick={_ => cyWrapper.layout##run()}>
            <Icons.Play />
          </ButtonIcon>
          <ButtonIcon onClick={_ => cyWrapper.layout##stop()}>
            <Icons.Pause />
          </ButtonIcon>
        </HFlex>
      </HFlex>,
      <div
        style=Css.(
          style([
            resize(vertical),
            overflow(hidden),
            padding(px(0)),
            height(px(pxHeight)),
          ])
        )>
        <div
          style=Css.(style([width(pct(100.)), height(pct(100.))]))
          ref={ReactDOMRe.Ref.domRef(containerRef)}
        />
      </div>,
    )
  </Panel>;
};
