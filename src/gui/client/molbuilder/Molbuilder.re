open Client_types;
open Components;
open Utils;
module MakeTable = Sandbox__generic_controls__table.MakeTable;
module Forms = Sandbox__generic_controls__forms;


module MolLibraryTable =
  MakeTable({
    let db_name = "mol_library";
});

module Form = Forms.Make({[@decco] type data_type = string});

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
  | CommitAcidItems(_) => prev_state
  | CommitMolecule(_) => prev_state
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

[@decco]
type data_full = {name: string, description: string, ts: float, data: string};

[@react.component]
let make = () => {
  let (showDialog, setShowDialog) = React.useState(() => None);
  let mol = Store.useSelector(Selector.mol);
  let storeDispatch = Store.useDispatch();

  let globalActions =
    React.useMemo1(
      () =>
        [|
          (
            onClick => <ButtonIcon key="dumps" onClick> <Icons.Save /> </ButtonIcon>,
            updateChange => setShowDialog(_ => Some(updateChange)),
          ),
        |],
      [|setShowDialog|],
    );

  let loadAction = name => Yaac.request(Fetch.Get, "/sandbox/db/mol_library/" ++ name, ~json_decode=data_full_decode, ())->Promise.getOk(res => Molbuilder__actions.commitMol(storeDispatch, res.data));


  <VFlex>
    <Modal isOpen={showDialog != None} onRequestClose={_ => setShowDialog(_ => None)}>
      <Form data=mol db_name="mol_library" setShow=setShowDialog />
    </Modal>
    <h1 className="title"> "Molbuilder"->React.string </h1>
    <MolLibraryTable update={() => ()} globalActions loadAction/>
    <Molbuilder__mol_panel mol />
    <HFlex> <MB_Cyto /> <Acids_panel /> </HFlex>
  </VFlex>;
};
