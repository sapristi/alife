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
    <Components.HFlex>
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
          <div className="panel-block content">
            <ul>
              <li> "Place"->React.string </li>
              <li> "Input arcs"->React.string <ul> <li> "Regular Input arc"->React.string </li> </ul> </li>
            </ul>
          </div>
        </div>
      </section>
      <section className="section"> <div className="box"> "List"->React.string </div> </section>
    </Components.HFlex>
  </Components.VFlex>;
};
