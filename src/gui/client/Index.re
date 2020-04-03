[%raw {|require('../static/semantic.min.css')|}];
[%raw "require('isomorphic-fetch')"]
module Main = {
  type window =
    | WSimulator
    | WSandbox
    | WMolbuilder;

  let get_classname = (fixed, current) =>
    if (fixed == current) {
      "active item";
    } else {
      "item";
    };
  [@react.component]
  let make = () => {
    let (current, setCurrent) = React.useState(() => WSimulator);

    React.useEffect1(
      () => {
        Js.log(current);
        None;
      },
      [|current|],
    );

    <div>
      <div className="ui top fixed menu">
        <a
          className={get_classname(WSimulator, current)}
          onClick={_ => setCurrent(_ => WSimulator)}>
          {React.string("Simulator")}
        </a>
        <a
          className={get_classname(WSandbox, current)}
          onClick={_ => setCurrent(_ => WSandbox)}>
          {React.string("Sandbox")}
        </a>
        <a
          className={get_classname(WMolbuilder, current)}
          onClick={_ => setCurrent(_ => WMolbuilder)}>
          {React.string("Molbuilder")}
        </a>
      </div>
      <div style={ReactDOMRe.Style.make(~paddingTop="40px", ())}>
        {switch (current) {
         | WSimulator => React.string("Simulator")
         | WSandbox => <Sandbox />
         | WMolbuilder => React.string("Molbuilder")
         }}
      </div>
    </div>;
  };
};

ReactDOMRe.renderToElementWithId(<Main />, "app");
