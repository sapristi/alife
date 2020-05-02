open Client_utils;
open Client_types;
%raw
"const cytoscape_utils = require('./../cytoscape/cytoscape_utils')";

type cytoscape_utils = {
  pnet_style: Cytoscape.style,
  cola_layout_conf: Cytoscape.layout_conf,
};

[@bs.val] external cytoscape_utils: cytoscape_utils = "cytoscape_utils";

[@react.component]
let make = (~selectedPnet) => {
  let containerRef: React.Ref.t(Js.Nullable.t(Dom.element)) =
    React.useRef(Js.Nullable.null);
  let (pnet, setPnet) = React.useState(() => None);
  /* let (cy, setCy) = React.useState(() => None); */
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
        /* setCy(_ => */
        /* Some( */
        let cy =
          Cytoscape.cytoscape({
            container,
            elements: Cytoscape.pnet_to_cytoscape_elements(pnet'),
            style: cytoscape_utils.pnet_style,
          });
        let layout = cy##layout(cytoscape_utils.cola_layout_conf);
        layout##run();
        ();
      | _ => ()
      };
      None;
    },
    (pnet, containerRef->React.Ref.current),
  );

  /* let cyEHandler = { */
  /*   set_node_selected: n => Js.log2("Select", n), */
  /*   set_node_unselected: () => Js.log("Unselect"), */
  /* }; */

  <div
    ref={ReactDOMRe.Ref.domRef(containerRef)}
    style=Css.(style([width(px(600)), height(px(600))]))
  />;
};
