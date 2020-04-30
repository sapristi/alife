[%raw "require('isomorphic-fetch')"];
[%raw "require('bulma')"];
[%raw "require('./style.css')"];
module Main = {
  type tab =
    | TSimulator
    | TSandbox
    | TMolbuilder;
  [@react.component]
  let make = () => {
    let (activeTab, setActiveTab) = React.useReducer((_, v) => v, TSandbox);

    <div>
      <Molecules.Tabs
        tabs=[
          (TSimulator, "Simulator"->React.string),
          (TSandbox, "Sandbox"->React.string),
          (TMolbuilder, "Molbuilder"->React.string),
        ]
        activeTab
        setActiveTab
      />
      <div style={ReactDOMRe.Style.make(~paddingTop="20px", ())}>
        {switch (activeTab) {
         | TSimulator => React.string("Simulator")
         | TSandbox => <Sandbox />
         | TMolbuilder => React.string("Molbuilder")
         }}
      </div>
    </div>;
  };
};

ReactDOMRe.renderToElementWithId(<Main />, "app");
