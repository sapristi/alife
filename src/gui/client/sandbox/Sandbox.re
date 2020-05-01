/* [@bs.val] [@bs.scope ("window", "location")] external origin : string = "origin"; */
open Client_utils;
open Client_types;
open Sandbox_components;

let reducer = (state: sandbox, action) => {
  switch (action) {
  | SetEnv(env) => {...state, env}
  | SetBact(bact) => {...state, bact}
  | SetSandbox(sandbox) => sandbox
  };
};

[@react.component]
let make = () => {
  let (sandbox, dispatch) = React.useReducer(reducer, default_sandbox);

  Js.log(("SANDBOX", sandbox));
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
  <div>
    <h1 className="title"> "Sandbox"->React.string </h1>
    <section className="section">
      <h2 className="subtitle"> "Generic controls"->React.string </h2>
      <Generic_controls env={sandbox.env} update dispatch />
    </section>
    <section className="section">
      <h2 className="subtitle"> "Inert molecules"->React.string </h2>
      <Inert_molecules inert_mols={sandbox.bact.inert_mols} update />
    </section>
    <section className="section">
      <h2 className="subtitle"> "Active molecules"->React.string </h2>
      <Active_molecules active_mols={sandbox.bact.active_mols} update />
    </section>
  </div>;
};
