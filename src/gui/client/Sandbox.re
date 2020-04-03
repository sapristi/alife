module GenericControls = {
  /* [@bs.val] [@bs.scope ("window", "location")] external origin : string = "origin"; */
  let origin = "http://localhost:1512";
  let update = () => {
    Js.Promise.(
      Fetch.fetchWithInit(
        origin ++ "/api/sandbox",
        Fetch.RequestInit.make(~method_=Get, ()),
      )
      |> then_(Fetch.Response.json)
      |> then_(json => Js.log(json) |> resolve)
    );
  };

  [@react.component]
  let make = () => {
    <div />;
  };
};

[@react.component]
let make = () => {
  ignore(GenericControls.update());
  Js.log(GenericControls.origin);
  Js.log(GenericControls.origin ++ "/api/sandbox");
  <div className="ui divided grid">
    <div className="centered row">
      <h1
        className="ui header"
        style={ReactDOMRe.Style.make(~marginTop="5px", ())}>
        {React.string("SandBox")}
      </h1>
    </div>
    <div className="row">
      <h2 className="ui horizontal divider header">
        {React.string("Bactery view")}
      </h2>
    </div>
  </div>;
};
