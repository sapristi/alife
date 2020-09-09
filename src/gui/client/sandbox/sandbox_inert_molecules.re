open Utils;
open Client_types;
open Components;

module ImolControls = {
  [@react.component]
  let make = (~imol: option(inert_mol), ~dispatch) => {
    let (qtt, setQtt) = React.useState(() => "");
    let (disabled, setDisabled) = React.useState(() => true);
    let store_dispatch = Store.useDispatch();

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
      Yaac.request(
        Fetch.Delete,
        "/sandbox/imol/" ++ imol_str,
        ~json_decode=bact_decode,
        (),
      )
      ->Promise.getOk(bact => dispatch(SetBact(bact)));
    };

    let setQuantity = _ => {
      let imol_str = Belt.Option.getExn(imol).mol;
      Yaac.request(
        Fetch.Put,
        "/sandbox/imol/" ++ imol_str ++ "?qtt=" ++ qtt,
        ~json_decode=bact_decode,
        (),
      )
      ->Promise.getOk(bact => dispatch(SetBact(bact)));
    };

    let send_to_molbuilder = _ => {
      switch (imol) {
      | Some(imol') =>
        Molbuilder__actions.commitMol(store_dispatch, imol'.mol)
      | None => ()
      };
    };

    <div className="tile is-vertical is-2">
      <div className="box">
        <Button disabled onClick=remove_selected>
          "Remove molecule"->React.string
        </Button>
        <Components.HFlex>
          <Button disabled onClick=setQuantity>
            "Set quantity"->React.string
          </Button>
          <Input.Text
            value=qtt
            disabled
            size=3
            setValue={new_value => setQtt(_ => new_value)}
          />
        </Components.HFlex>
        <Button disabled onClick=send_to_molbuilder>
          "Send to molbuilder"->React.string
        </Button>
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
      <td> imol.qtt->React.int </td>
      <td> {imol.ambient->string_of_bool->React.string} </td>
    </React.Fragment>;

  <div className="tile" style=Css.(style([alignItems(center)]))>
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
