open Belt;
open Utils;
/* open Types; */
open Acid_types;
open Client_types;
/* type state = { */
/*   mol: Molecule.t, */
/*   pnet: option(Petri_net.t), */
/*   prot: string, */
/* }; */

/* let initial_state = {mol: "", pnet: None, prot: ""}; */

module Styles = {
  open Css;

  global("container-hovered", [background(darkgray), minWidth(px(100)), minHeight(px(100))]);
};

[@react.component]
let make = () => {
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
        <Molbuilder__acids_panel />
      </Components.HFlex>
    </Components.VFlex>;
    /* Js.log2("Molbuilder", acids); */
    /* let (state, dispatch) = React.useReducer((x, y) => x, initial_state); */
};
