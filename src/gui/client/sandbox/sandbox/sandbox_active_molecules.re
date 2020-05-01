open Client_utils;
open Client_types;
let make_width = (wpct: float) => Css.(style([width(pct(wpct))]));

module AmolControls = {
  [@react.component]
  let make = (~amol: option(active_mol)) => {
    let (disabled, setDisabled) = React.useState(() => true);

    React.useEffect1(
      () => {
        switch (amol) {
        | Some(amol') => setDisabled(_ => false)
        | None => setDisabled(_ => true)
        };
        None;
      },
      [|amol|],
    );

    <div className="tile is-vertical is-2">
      <div className="box">
        <button className="button" disabled>
          "Remove molecule"->React.string
        </button>
        <button className="button" disabled>
          "Send to molbuilder"->React.string
        </button>
      </div>
    </div>;
  };
};

[@react.component]
let make = (~active_mols, ~update) => {
  let (selected, setSelected) = React.useState(() => None);

  let tr_classname = mol =>
    if (Some(mol) == selected) {
      "is-selected";
    } else {
      "";
    };
  <div className="tile">
    <div className="tile is-10">
      <table
        className="table is-fullwidth is-striped"
        style=Css.(style([width(pct(100.))]))>
        <colgroup>
          <col span=1 style={make_width(85.)} />
          <col span=1 style={make_width(15.)} />
        </colgroup>
        <thead>
          <tr>
            <th> "Molecule"->React.string </th>
            <th> "Quantity"->React.string </th>
          </tr>
        </thead>
        <tbody>
          {Generics.react_list(
             List.map(
               (amol: active_mol) =>
                 <tr
                   key={amol.mol}
                   onClick={_ => setSelected(_ => Some(amol))}
                   className={tr_classname(amol)}>
                   <td> <p> amol.mol->React.string </p> </td>
                   <td> {amol.qtt->string_of_int->React.string} </td>
                 </tr>,
               active_mols,
             ),
           )}
        </tbody>
      </table>
    </div>
    <AmolControls amol=selected />
  </div>;
};
