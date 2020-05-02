open Client_utils;
open Client_types;

module ImolControls = {
  [@react.component]
  let make = (~imol: option(inert_mol), ~dispatch) => {
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

    let remove_selected = _ => {
      let imol_str = Belt.Option.getExn(imol).mol;
      YaacApi.request(
        Fetch.Delete,
        "/sandbox/imol/" ++ imol_str,
        ~json_decode=bact_decode,
        ~callback=bact => dispatch(SetBact(bact)),
        (),
      )
      ->ignore;
    };

    <div className="tile is-vertical is-2">
      <div className="box">
        <button className="button" disabled onClick=remove_selected>
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
let make = (~inert_mols, ~update, ~dispatch) => {
  let (selected, setSelected) = React.useState(() => None);

  let make_imol_row = (imol: inert_mol) =>
    <React.Fragment>
      <td style=Css.(style([overflowWrap(breakWord)]))>
        imol.mol->React.string
      </td>
      <td> {imol.qtt->string_of_int->React.string} </td>
      <td> {imol.ambient->string_of_bool->React.string} </td>
    </React.Fragment>;

  <div className="tile">
    <div className="tile">
      <Sandbox_moltable
        col_widths=[70., 15., 15.]
        headers=["Molecule", "Quantity", "Ambient"]
        data=inert_mols
        make_row=make_imol_row
        selected
        setSelected
        get_key={(imol: inert_mol) => imol.mol}
      />
    </div>
    <ImolControls imol=selected dispatch />
  </div>;
};
