open Utils;

type event_handler = Js.Json.t => unit;

[@react.component]
let make = (~selectedPnet, ~updateSwitch, ~dispatch) => {
  let (pnetData, setPnetData) = React.useState(() => None);
  let (selectedNode, setSelectedNode) =
    React.useState(() => Cytoscape.Elements.NoNode);

  let cyEHandler = x => {
    switch (Cytoscape.Elements.node_type_decode(x)) {
    | Ok(node) => setSelectedNode(_ => node)
    | Error(e) =>
      Js.log3("Could not decode", x, e);
      setSelectedNode(_ => NoNode);
    };
  };

  React.useEffect2(
    () => {
      switch (selectedPnet) {
      | None =>
        setSelectedNode(_ => NoNode);
        setPnetData(_ => None);
      | Some((mol, pnet_id)) =>
        setSelectedNode(_ => NoNode);
        Yaac.request(
          Fetch.Get,
          "/sandbox/amol/" ++ mol ++ "/pnet/" ++ pnet_id->string_of_int,
          ~json_decode=Types.Petri_net.t_decode,
          (),
        )
        ->Promise.getOk(res => {
            setPnetData(_ => Some((Some(pnet_id), res)))
          });
      };
      None;
    },
    (selectedPnet, updateSwitch),
  );

  <div className="tile">
    <Cytoscape_pnet
      pnetO=pnetData
      cyEHandler
      styles=Css.[width(pct(100.))]
      collapsable=true
      pxHeight=600
    />
    <div className="tile is-vertical">
      {switch (pnetData, selectedNode) {
       | (None, _) => React.null
       | (Some((_, pnet)), NPlace(i)) =>
         <Sandbox_pnet_place pnet place_id=i />
       | (Some((_, pnet)), NTransition(i)) =>
         <Sandbox_pnet_transition pnet transition_id=i dispatch />
       | (_, NoNode) => React.null
       }}
    </div>
  </div>;
};
