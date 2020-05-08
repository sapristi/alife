/* open Client_utils; */
open Types;

type state = {
  mol: Molecule.t,
  pnet: option(Petri_net.t),
  prot: string,
};

let initial_state = {mol: "", pnet: None, prot: ""};

[@react.component]
let make = () => {
  let (state, dispatch) = React.useReducer((x, y) => x, initial_state);

  <Components.VFlex>
    <h1 className="title"> "Molbuilder"->React.string </h1>
    <section className="section">
      <Cytoscape_pnet
        pnetIdO=None
        pnetO=None
        cyEHandler={_ => ()}
        styles=Css.[width(px(200)), height(px(200))]
      />
    </section>
    <section className="section">
      <div className="panel">
        <p className="panel-heading"> "Proteines"->React.string </p>
        <div className="panel-block content"> <ul> <li> "ok"->React.string </li> </ul> </div>
      </div>
    </section>
  </Components.VFlex>;
};
