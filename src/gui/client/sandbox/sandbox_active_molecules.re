open Client_types;
open Utils;
open Components;
let make_width = (wpct: float) => Css.(style([width(pct(wpct))]));

module AmolControls = {
  [@decco]
  type pnet_ids = list(int);

  [@react.component]
  let make = (~amol: option(active_mol), ~dispatch, ~update) => {
    let (disabled, setDisabled) = React.useState(() => true);
    let (pnet_ids, setPnet_ids) = React.useState(() => []);
    let (selectedPnet, setSelectedPnet) = React.useState(() => None);
    let store_dispatch = Store.useDispatch();

    React.useEffect1(
      () => {
        switch (amol) {
        | Some(amol') =>
          setDisabled(_ => false);
          Yaac.request(
            Fetch.Get,
            "/sandbox/amol/" ++ amol'.mol,
            ~json_decode=pnet_ids_decode,
            (),
          )
          ->Promise.getOk(pnet_ids' => {
              Js.log3("Callback", pnet_ids', selectedPnet);
              setPnet_ids(_ => pnet_ids');
              switch (selectedPnet, pnet_ids') {
              | (None, [pnet_id, ..._]) =>
                setSelectedPnet(_ => Some((amol'.mol, pnet_id)))
              | (Some((_, prev_pnet_id)), [pnet_id, ..._]) =>
                if (!List.exists(x => x == prev_pnet_id, pnet_ids')) {
                  setSelectedPnet(_ => Some((amol'.mol, pnet_id)));
                }
              | _ => setSelectedPnet(_ => None)
              };
            });
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

    let send_to_molbuilder = _ => {
      switch (selectedPnet) {
      | Some((mol, _)) => Molbuilder__actions.commitMol(store_dispatch, mol)
      | None => ()
      };
    };

    let remove_pnet = _ => {
      switch (amol, selectedPnet) {
      | (Some(amol'), Some(pnetId)) =>
        let mol = amol'.mol;
        Yaac.request_unit(
          Fetch.Delete,
          {j| /api/sandbox/amol/$(mol)/pnet/$(pnetId) |j},
          (),
        )
        ->Promise.getOk(update);
      | _ => ()
      };
    };
    <div className="tile is-vertical is-2">
      <div className="box">
        <Components.HFlex>
          "Pnet selection"->React.string
          <div className="select">
            <select
              onChange={event =>
                event |> Generics.event_to_value |> handlePnetIdChange
              }>
              {Generics.react_list(
                 List.map(
                   i => {
                     let i_str = i->string_of_int;
                     <option key=i_str value=i_str>
                       i_str->React.string
                     </option>;
                   },
                   pnet_ids,
                 ),
               )}
            </select>
          </div>
        </Components.HFlex>
        <Button disabled onClick=remove_pnet>
          "Remove molecule"->React.string
        </Button>
        <Button disabled onClick=send_to_molbuilder>
          "Send to molbuilder"->React.string
        </Button>
      </div>
    </div>;
  };
};

[@react.component]
let make = (~active_mols, ~update, ~dispatch) => {
  let (selected, setSelected) = React.useState(() => None);

  let make_amol_row = (amol: active_mol) =>
    <React.Fragment>
      <td style=Css.(style([overflowWrap(breakWord)]))>
        amol.mol->React.string
      </td>
      <td> amol.qtt->React.int </td>
    </React.Fragment>;

  <div className="tile" style=Css.(style([alignItems(center)]))>
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
    <AmolControls amol=selected dispatch update />
  </div>;
};
