open Client_types;
open Utils;
let make_width = (wpct: float) => Css.(style([width(pct(wpct))]));

module AmolControls = {
  [@decco]
  type pnet_ids = list(int);

  [@react.component]
  let make = (~amol: option(active_mol), ~dispatch) => {
    let (disabled, setDisabled) = React.useState(() => true);
    let (pnet_ids, setPnet_ids) = React.useState(() => []);
    let (selectedPnet, setSelectedPnet) = React.useState(() => None);

    React.useEffect1(
      () => {
        switch (amol) {
        | Some(amol') =>
          setDisabled(_ => false);
          Yaac.request(
            Fetch.Get,
            "/sandbox/amol/" ++ amol'.mol,
            ~json_decode=pnet_ids_decode,
            ~callback=
              pnet_ids' => {
                Js.log3("Callback", pnet_ids', selectedPnet);
                setPnet_ids(_ => pnet_ids');
                switch (selectedPnet, pnet_ids') {
                | (None, [pnet_id, ..._]) => setSelectedPnet(_ => Some((amol'.mol, pnet_id)))
                | (Some((_, prev_pnet_id)), [pnet_id, ..._]) =>
                  if (!List.exists(x => x == prev_pnet_id, pnet_ids')) {
                    setSelectedPnet(_ => Some((amol'.mol, pnet_id)));
                  }
                | _ => setSelectedPnet(_ => None)
                };
              },
            (),
          )
          ->ignore;
        | None =>
          setDisabled(_ => true);
          setPnet_ids(_ => []);
          setSelectedPnet(_ => None);
        };
        None;
      },
      [|amol|],
    );

    React.useEffect1(
      () => {
        Js.log2("Selected pnet", selectedPnet);
        dispatch(SetSelectedPnet(selectedPnet));
        None;
      },
      [|selectedPnet|],
    );

    let handlePnetIdChange = value => {
      Js.log2("Pnet sel changed", value);
      switch (amol) {
      | None => ()
      | Some(amol') => setSelectedPnet(_ => Some((amol'.mol, value)))
      };
    };

    <div className="tile is-vertical is-2">
      <div className="box">
        <Components.HFlex>
          "Pnet selection"->React.string
          <div className="select">
            <select onChange={event => event |> Generics.event_to_value |> handlePnetIdChange}>
              {Generics.react_list(
                 List.map(
                   i => {
                     let i_str = i->string_of_int;
                     <option key=i_str value=i_str> i_str->React.string </option>;
                   },
                   pnet_ids,
                 ),
               )}
            </select>
          </div>
        </Components.HFlex>
        <button className="button" disabled> "Remove molecule"->React.string </button>
        <button className="button" disabled> "Send to molbuilder"->React.string </button>
      </div>
    </div>;
  };
};

[@react.component]
let make = (~active_mols, ~update, ~dispatch) => {
  let (selected, setSelected) = React.useState(() => None);

  let make_amol_row = (amol: active_mol) =>
    <React.Fragment>
      <td className=Css.(style([overflowWrap(breakWord)]))> amol.mol->React.string </td>
      <td> amol.qtt->React.int </td>
    </React.Fragment>;

  <div className={Cn.make(["tile", Css.(style([alignItems(center)]))])}>
    <div className="tile is-10">
      <Sandbox_moltable
        col_widths=[85., 15.]
        headers=["Molecule", "Quantity"]
        data=active_mols
        make_row=make_amol_row
        selected
        setSelected
        get_key={(amol: active_mol) => amol.mol}
      />
    </div>
    <AmolControls amol=selected dispatch />
  </div>;
};
