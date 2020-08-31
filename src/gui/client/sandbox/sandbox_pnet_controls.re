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

  React.useEffect1(
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
            Js.log2("Res", res);
            setPnetData(_ => Some(res));
          });
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
        Yaac.request(
          Fetch.Get,
          "/sandbox/amol/" ++ mol ++ "/pnet/" ++ pnet_id->string_of_int,
          ~json_decode=Types.Petri_net.t_decode,
          (),
        )
        ->Promise.getOk(res => {
            Js.log2("Res", res);
            setPnetData(_ => Some(res));
          })
      };
      None;
    },
    [|updateSwitch|],
  );

  <div className="tile">
    <Cytoscape_pnet
      pnetIdO={Belt.Option.map(selectedPnet, ((_, y)) => y)}
      pnetO=pnetData
      styles=Css.[width(pct(100.)), height(px(600))]
      cyEHandler
    />
    <div className="tile is-vertical">
      {switch (pnetData, selectedNode) {
       | (None, _) => React.null
       | (Some(pnet), NPlace(i)) => <Sandbox_pnet_place pnet place_id=i />
       | (Some(pnet), NTransition(i)) =>
         <Sandbox_pnet_transition pnet transition_id=i dispatch />
       | (_, NoNode) => React.null
       }}
    </div>
  </div>;
};
