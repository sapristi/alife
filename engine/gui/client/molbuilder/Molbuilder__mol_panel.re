open Components;
open Utils;

let bc = Utils.BroadcastChannel.make("yaac");

let send_mol_to_sandbox = mol =>
  Yaac.request_unit(Fetch.Post, "/sandbox/mol/" ++ mol, ())->Promise.getOk(
  () => {
    Js.log3("BC", bc, bc##postMessage);
    bc##postMessage("update");
  }
);

[@react.component]
let make = (~mol) => {
  let (innerMol, setInnerMol) = React.useState(() => "");
  React.useEffect1(
    () => {
      setInnerMol(_ => mol);
      None;
    },
    [|mol|],
  );

  let (autocommit, setAutocommit) = React.useState(() => false);
  let storeDispatch = Store.useDispatch();
  let commitMolecule = _ =>
    Molbuilder__actions.commitMol(storeDispatch, innerMol);

  React.useEffect1(
    () => {
      if (autocommit) {
        commitMolecule();
      };
      None;
    },
    [|innerMol|],
  );

  <Panel>
    (
      <HFlex style=Css.[alignItems(center), justifyContent(spaceBetween)]>
        "Molecule"->React.string
        <HFlex>
          <Button onClick={_ => send_mol_to_sandbox(innerMol)}>
            "Send to Sanbox"->React.string
          </Button>
          <Button onClick=commitMolecule> "Commit"->React.string </Button>
          <Input.Checkbox
            state=autocommit
            setState=setAutocommit
            label="Auto-commit"
            id="mol_auto_commit"
          />
        </HFlex>
      </HFlex>,
      <Input.Text
        value=innerMol
        onChange={v => setInnerMol(_ => v)}
        multiline=true
      />,
    )
  </Panel>;
};
