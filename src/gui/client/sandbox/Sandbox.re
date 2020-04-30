/* [@bs.val] [@bs.scope ("window", "location")] external origin : string = "origin"; */
open Client_utils;
open Sandbox_components;

[@react.component]
let make = () => {
  let (sandbox, setSandbox) =
    Generics.useStateSimple(() => Client_types.default_sandbox);

  Js.log(("SANDBOX", sandbox));
  let update = _ => {
    ignore(
      YaacApi.get("/api/sandbox", res => {
        switch (Client_types.sandbox_decode(res)) {
        | Ok(sandbox) => setSandbox(_ => sandbox)
        | Error(e) => Js.log3("Error decoding", res, e)
        }
      }),
    );
  };
  React.useEffect(() => {
    update();
    None;
  });
  <div>
    <h1 className="title"> "Sandbox"->React.string </h1>
    <section className="section">
      <h2 className="subtitle"> "Bactery view"->React.string </h2>
      <Generic_controls env={sandbox.env} update />
    </section>
  </div>;
};
