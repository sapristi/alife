/* [@bs.val] [@bs.scope ("window", "location")] external origin : string = "origin"; */
open MaterialUi;

[@react.component]
let make = () => {
  let (sandbox, setSandbox) =
    Client_utils.useStateSimple(() => Client_types.default_sandbox);

  let update = _ => {
    ignore(
      Client_utils.get("/api/sandbox", res => {
        switch (Client_types.sandbox_decode(res)) {
        | Ok(sandbox) => setSandbox(_ => sandbox)
        | Error(e) => Js.log(("Error decoding", res, e))
        }
      }),
    );
  };
  update();
  <div>
    <Typography variant=`H2> "Sandbox"->React.string </Typography>
    <Divider />
    <Typography variant=`H3> "Bactery view"->React.string </Typography>
    <Generic_controls env={sandbox.env} update />
  </div>;
};
