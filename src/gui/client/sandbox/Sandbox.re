/* [@bs.val] [@bs.scope ("window", "location")] external origin : string = "origin"; */
open Utils;
open Client_types;
open Components;

module GenericControls = Sandbox__generic_controls;

let pendingSelector = (store: Store.appState) => store.pendingRequest;

module SidePanel = {
  [@react.component]
  let make = (~dispatch) => {
    let pending = Store.useSelector(pendingSelector);
    let (nr, setNr) = React.useState(() => 1);

    let next_reactions = i => {
      Yaac.request(
        Fetch.Post,
        "/sandbox/reaction/next/" ++ i->string_of_int,
        ~json_decode=bact_decode,
        (),
      )
      ->Promise.getOk(new_bact => {
          dispatch(SetBact(new_bact));
          dispatch(SwitchUpdate);
        });
    };

    <div
      className="box" style=Css.(style([position(fixed), zIndex(1000), padding(rem(0.5))]))>
      <Components.VFlex>
        <Button onClick={_ => next_reactions(1)}> "React!"->React.string </Button>
        <Input.Text
          styles=Css.[maxWidth(px(100))]
          size=1
          value={nr->string_of_int}
          onChange={v => {
            switch (Belt.Int.fromString(v)) {
            | None => ()
            | Some(i) => setNr(_' => i)
            }
          }}
        />
        <Button onClick={_ => next_reactions(nr)}> "React!"->React.string </Button>
        <Loader active=pending />
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

let bc = BroadcastChannel.make("yaac");

[@react.component]
let make = () => {
  let (state, dispatch) =
    React.useReducer(
      reducer,
      {sandbox: default_sandbox, selectedPnet: None, updateSwitch: false},
    );

  Js.log2("Sandbox", state);

  let loadState =
    React.useCallback1(
      _ => {
        Yaac.request(Fetch.Get, "/sandbox", ~json_decode=sandbox_decode, ())
        ->Promise.getOk(sandbox => dispatch(SetSandbox(sandbox)))
      },
      [|dispatch|],
    );

  let update = React.useCallback1(_ => dispatch(SwitchUpdate), [|dispatch|]);

  React.useEffect1(
    () => {
      bc##onmessage
      #= Some(
           message => {
             Js.log2("YOU GOT A MESGGAGE", message);
             if (message.data === "update") {
               dispatch(SwitchUpdate);
             };
           },
         );

      None;
    },
    [|dispatch|],
  );

  React.useEffect1(
    () => {
      loadState();
      None;
    },
    [|state.updateSwitch|],
  );
  <Components.VFlex>
    <SidePanel dispatch />
    <div style=Css.(style([flexGrow(0.), paddingLeft(px(100))]))>
      <h1 className="title nice-title"> "Sandbox"->React.string </h1>
      <section className="section">
        <Panel collapsable=true>
          (
            "Generic controls"->React.string,
            <GenericControls
              env={state.sandbox.env}
              seed={state.sandbox.seed}
              update
              dispatch
            />,
          )
        </Panel>
      </section>
      <section className="section">
        <Panel collapsable=true>
          (
            "Inert molecules"->React.string,
            <Sandbox_inert_molecules
              inert_mols={state.sandbox.bact.inert_mols}
              update
              dispatch
            />,
          )
        </Panel>
      </section>
      <section className="section">
        <Panel collapsable=true>
          (
            "Active molecules"->React.string,
            <Sandbox_active_molecules
              active_mols={state.sandbox.bact.active_mols}
              update
              dispatch
            />,
          )
        </Panel>
      </section>
      {switch (state.selectedPnet) {
       | None => React.null
       | Some(_) =>
         <section className="section">
           <Sandbox_pnet_controls
             selectedPnet={state.selectedPnet}
             updateSwitch={state.updateSwitch}
             dispatch
           />
         </section>
       }}
      <section className="section">
        <Sandbox__reactions updateSwitch={state.updateSwitch} />
      </section>
    </div>
  </Components.VFlex>;
};
