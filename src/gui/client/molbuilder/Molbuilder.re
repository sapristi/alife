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

[@react.component]
let make = () => {
  let (state, setState) =
    React.useState(() => {proteine: [||], molecule: "", pnet: None});
  let commitAcidItems = prot =>
    Yaac.request(
      Fetch.Post,
      "/utils/build/from_prot",
      ~payload=proteine_encode(prot),
      ~json_decode=commitAcidItemsResponse_decode,
      (),
    )
    ->Promise.getOk(({mol, pnet}) => {
        setState(prevState => {...prevState, molecule: mol, pnet})
      });

  <Components.VFlex>
    <h1 className="title"> "Molbuilder"->React.string </h1>
    <Components.HFlex>
      <section className="section">
        <Cytoscape_pnet
          pnetIdO=None
          pnetO={state.pnet}
          cyEHandler={_ => ()}
          styles=Css.[width(px(200)), height(px(200))]
        />
      </section>
      <Acids_panel commit={prot => commitAcidItems(prot)} />
    </Components.HFlex>
  </Components.VFlex>;
};
