[%raw "require('isomorphic-fetch')"];
[%raw "require('bulma')"];
[%raw "require('./static/style.css')"];
[%raw "require('./static/mystyles.scss')"];

module Main = {
  type tab =
    | TSimulator
    | TSandbox
    | TMolbuilder
    | TLogs
    | Tests;

  [@react.component]
  let make = () => {
    let (activeTab, setActiveTab) = React.useReducer((_, v) => v, TSandbox);
    <Store.Provider store=Store.appStore>
      <div>
        <Components.Tabs
          tabs=[
            (TSimulator, "Simulator"->React.string),
            (TSandbox, "Sandbox"->React.string),
            (TMolbuilder, "Molbuilder"->React.string),
            (TLogs, "Control logs"->React.string),
          ]
          activeTab
          setActiveTab
        />
        <div>
          {switch (activeTab) {
           | TSimulator => React.string("Simulator")
           | TSandbox => <Sandbox />
           | TMolbuilder => <Molbuilder />
           | Tests => <Tests.RenderApp />
           | TLogs => <Log_tree />
           }}
        </div>
      </div>
    </Store.Provider>;
  };
};

ReactDOMRe.renderToElementWithId(<Main />, "app");