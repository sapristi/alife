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

  global(
    "container-hovered",
    [background(darkgray), minWidth(px(100)), minHeight(px(100))],
  );
};
module Acids_panel = Molbuilder__acids_panel;

type state = {
  proteine,
  molecule: string,
  pnet: option(Types.Petri_net.t),
};

type action =
  | CommitAcidItems(proteine)
  | CommitMolecule(string);

[@decco]
type commitAcidItemsResponse = {
  mol: string,
  pnet: option(Types.Petri_net.t),
};
let reducer = (prev_state, action: action) => {
  switch (action) {
  | CommitAcidItems(proteine) => prev_state
  | CommitMolecule(mol) => prev_state
  };
};

module Selector = {
  let pnet = (state: Store.appState) => state.molbuilder.pnet;
  let mol = (state: Store.appState) => state.molbuilder.mol;
  let proteine = (state: Store.appState) => state.molbuilder.proteine;
};

module MB_Cyto = {
  [@react.component]
  let make = () => {
    let pnet = Store.useSelector(Selector.pnet);
    <Cytoscape_pnet
      pnetIdO=None
      pnetO=pnet
      cyEHandler={_ => ()}
      styles=Css.[width(pct(100.)), height(px(200))]
    />;
  };
};

[@react.component]
let make = () => {
  let mol = Store.useSelector(Selector.mol);

  <Components.VFlex>
    <h1 className="title"> "Molbuilder"->React.string </h1>
    <Molbuilder__mol_panel mol />
    <Components.HFlex> <MB_Cyto /> <Acids_panel /> </Components.HFlex>
  </Components.VFlex>;
};
