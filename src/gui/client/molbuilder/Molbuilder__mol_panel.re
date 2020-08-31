open Components;

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

  <div className="panel">
    <HFlex
      className="panel-heading"
      style=Css.[alignItems(center), justifyContent(spaceBetween)]>
      "Molecule"->React.string
      <HFlex>
        <button className="button" onClick=commitMolecule>
          "Commit"->React.string
        </button>
        <Input.Checkbox
          state=autocommit
          setState=setAutocommit
          label="Auto-commit"
          id="mol_auto_commit"
        />
      </HFlex>
    </HFlex>
    <div className="panel-block content">
      <Components.Input.Text
        value=innerMol
        setValue=setInnerMol
        multiline=true
      />
    </div>
  </div>;
};
