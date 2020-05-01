open Client_utils;
open Client_types;
let make_width = (wpct: float) => Css.(style([width(pct(wpct))]));

module ImolControls = {
  [@react.component]
  let make = (~imol: option(inert_mol)) => {
    let (qtt, setQtt) = React.useState(() => "");
    let (disabled, setDisabled) = React.useState(() => true);

    React.useEffect1(
      () => {
        switch (imol) {
        | Some(imol') =>
          setQtt(_ => imol'.qtt->string_of_int);
          setDisabled(_ => false);
        | None =>
          setQtt(_ => "");
          setDisabled(_ => true);
        };
        None;
      },
      [|imol|],
    );

    <div className="tile is-vertical is-2">
      <div className="box">
        <button className="button" disabled>
          "Remove molecule"->React.string
        </button>
        <Molecules.HFlex style=[]>
          <button className="button" disabled>
            "Set quantity"->React.string
          </button>
          <input
            className="input"
            type_="text"
            value=qtt
            width="10"
            disabled
            onChange={event => {
              let new_value = event->Generics.event_to_value;
              setQtt(_ => new_value);
            }}
          />
        </Molecules.HFlex>
        <button className="button" disabled>
          "Send to molbuilder"->React.string
        </button>
      </div>
    </div>;
  };
};

[@react.component]
let make = (~inert_mols, ~update) => {
  let (selected, setSelected) = React.useState(() => None);

  let tr_classname = mol =>
    if (Some(mol) == selected) {
      "is-selected";
    } else {
      "";
    };
  <div className="tile">
    <div className="tile">
      <table className="table is-fullwidth is-striped">
        <colgroup>
          <col span=1 style={make_width(70.)} />
          <col span=1 style={make_width(15.)} />
          <col span=1 style={make_width(15.)} />
        </colgroup>
        <thead>
          <tr>
            <th> "Molecule"->React.string </th>
            <th> "Quantity"->React.string </th>
            <th> "Ambient"->React.string </th>
          </tr>
        </thead>
        <tbody>
          {Generics.react_list(
             List.map(
               (imol: inert_mol) =>
                 <tr
                   key={imol.mol}
                   onClick={_ => setSelected(_ => Some(imol))}
                   className={tr_classname(imol)}>
                   <td> imol.mol->React.string </td>
                   <td> {imol.qtt->string_of_int->React.string} </td>
                   <td> {imol.ambient->string_of_bool->React.string} </td>
                 </tr>,
               inert_mols,
             ),
           )}
        </tbody>
      </table>
    </div>
    <ImolControls imol=selected />
  </div>;
};
