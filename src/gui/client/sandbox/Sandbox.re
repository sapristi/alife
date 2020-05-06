/* [@bs.val] [@bs.scope ("window", "location")] external origin : string = "origin"; */
open Client_utils;
open Client_types;

module SidePanel = {
  [@react.component]
  let make = (~dispatch) => {
    let (nr, setNr) = React.useState(() => 1);

    let next_reactions = i => {
      YaacApi.request(
        Fetch.Post,
        "/sandbox/reaction/next/" ++ i->string_of_int,
        ~json_decode=bact_decode,
        ~callback=
          new_bact => {
            dispatch(SetBact(new_bact));
            dispatch(SwitchUpdate);
          },
        (),
      )
      ->ignore;
    };
    <div style=Css.(style([position(fixed), zIndex(1000), padding(rem(0.5))])) className="box">
      <Components.VFlex>
        <button className="button" onClick={_ => next_reactions(1)}> "React!"->React.string </button>
        <input
          className="input"
          type_="text"
          size=1
          style=Css.(style([maxWidth(px(100))]))
          value={nr->string_of_int}
          onChange={e => {
            let v = e->Generics.event_to_value;
            switch (Belt.Int.fromString(v)) {
            | None => ()
            | Some(i) => setNr(_ => i)
            };
          }}
        />
        <button className="button" onClick={_ => next_reactions(nr)}> "React!"->React.string </button>
      </Components.VFlex>
    </div>;
  };
};

type sandboxState = {
  sandbox,
  selectedPnet: option((string, int)),
  updateSwitch: bool,
};

let reducer = (state: sandboxState, action) => {
  switch (action) {
  | SetEnv(env) => {
      ...state,
      sandbox: {
        ...state.sandbox,
        env,
      },
    }
  | SetBact(bact) => {
      ...state,
      sandbox: {
        ...state.sandbox,
        bact,
      },
    }
  | SetSandbox(sandbox) => {...state, sandbox}
  | SetSelectedPnet(selectedPnet) => {...state, selectedPnet}
  | SwitchUpdate => {...state, updateSwitch: !state.updateSwitch}
  };
};

[@react.component]
let make = () => {
  let (state, dispatch) =
    React.useReducer(reducer, {sandbox: default_sandbox, selectedPnet: None, updateSwitch: false});

  Js.log2("Sandbox", state);

  let update = _ => {
    ignore(
      YaacApi.get("/sandbox", res => {
        switch (Client_types.sandbox_decode(res)) {
        | Ok(sandbox) => dispatch(SetSandbox(sandbox))
        | Error(e) => Js.log3("Error decoding", res, e)
        }
      }),
    );
  };
  React.useEffect0(() => {
    update();
    None;
  });
  Js.log(("SANDBOX", state));
  <Components.VFlex>
    <SidePanel dispatch />
    <div style=Css.(style([flexGrow(0.), paddingLeft(px(100))]))>
      <h1 className="title"> "Sandbox"->React.string </h1>
      <section className="section">
        <h2 className="subtitle"> "Generic controls"->React.string </h2>
        <Sandbox_generic_controls env={state.sandbox.env} update dispatch />
      </section>
      <section className="section">
        <h2 className="subtitle"> "Inert molecules"->React.string </h2>
        <Sandbox_inert_molecules inert_mols={state.sandbox.bact.inert_mols} update dispatch />
      </section>
      <section className="section">
        <h2 className="subtitle"> "Active molecules"->React.string </h2>
        <Sandbox_active_molecules active_mols={state.sandbox.bact.active_mols} update dispatch />
      </section>
      <section className="section">
        <h2 className="subtitle"> "Petri Net"->React.string </h2>
        <Sandbox_pnet_controls selectedPnet={state.selectedPnet} updateSwitch={state.updateSwitch} dispatch />
      </section>
    </div>
  </Components.VFlex>;
};
