open Belt;
open Utils;
open Acid_types;
open Client_types;
open Components;

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
  let pnet = (state: Store.appState) => {
    Belt.Option.map(state.molbuilder.pnet, pnet => (None, pnet));
  };
  let mol = (state: Store.appState) => state.molbuilder.mol;
  let proteine = (state: Store.appState) => state.molbuilder.proteine;
};

module MB_Cyto = {
  [@react.component]
  let make = () => {
    let pnetO = Store.useSelector(Selector.pnet);

    <Cytoscape_pnet
      pnetO
      styles=Css.[width(pct(100.)), height(pct(100.))]
      cyEHandler={_ => ()}
      pxHeight=400
    />;
  };
};

[@react.component]
let make = () => {
  let mol = Store.useSelector(Selector.mol);

  <VFlex>
    <h1 className="title"> "Molbuilder"->React.string </h1>
    <Molbuilder__mol_panel mol />
    <HFlex> <MB_Cyto /> <Acids_panel /> </HFlex>
  </VFlex>;
};
