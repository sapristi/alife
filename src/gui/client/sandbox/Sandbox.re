/* [@bs.val] [@bs.scope ("window", "location")] external origin : string = "origin"; */
open Client_utils;
open Client_types;
open Sandbox_components;

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
    React.useReducer(
      reducer,
      {sandbox: default_sandbox, selectedPnet: None, updateSwitch: false},
    );

  Js.log2("Sandbox", state);

  let next_reactions = i => {
    YaacApi.request(
      Fetch.Post,
      "/sandbox/reaction/next/" ++ i,
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
  <div style=Css.(style([display(`flex), flexDirection(`row)]))>
    <div style=Css.(style([position(fixed)]))>
      <button className="button" onClick={_ => next_reactions("1")}>
        "Next reaction"->React.string
      </button>
    </div>
    <div style=Css.(style([flexGrow(0.), paddingLeft(px(30))]))>
      <h1 className="title"> "Sandbox"->React.string </h1>
      <section className="section">
        <h2 className="subtitle"> "Generic controls"->React.string </h2>
        <Generic_controls env={state.sandbox.env} update dispatch />
      </section>
      <section className="section">
        <h2 className="subtitle"> "Inert molecules"->React.string </h2>
        <Inert_molecules
          inert_mols={state.sandbox.bact.inert_mols}
          update
          dispatch
        />
      </section>
      <section className="section">
        <h2 className="subtitle"> "Active molecules"->React.string </h2>
        <Active_molecules
          active_mols={state.sandbox.bact.active_mols}
          update
          dispatch
        />
      </section>
      <section className="section">
        <h2 className="subtitle"> "Petri Net"->React.string </h2>
        <Pnet_controls
          selectedPnet={state.selectedPnet}
          updateSwitch={state.updateSwitch}
        />
      </section>
    </div>
  </div>;
};
