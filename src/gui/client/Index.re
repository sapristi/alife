[%raw "require('isomorphic-fetch')"];
[%raw "require('bulma')"];
[%raw "require('./static/style.css')"];
[%raw "require('./static/mystyles.scss')"];

module OldMain = {
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

module SimulatorDummy = {
  [@react.component]
  let make = () => {
    React.string("Simulator");
  };
};

module type TAB_COMPONENT = (module type of SimulatorDummy);

module Main = {
  type tab =
    | TSimulator
    | TSandbox
    | TMolbuilder
    | TLogs
    | TTests;

  let tab_name = tab =>
    switch (tab) {
    | TSimulator => "Simulator"
    | TSandbox => "Sandbox"
    | TMolbuilder => "Molbuilder"
    | TLogs => "Control logs"
    | TTests => "Tests"
    };

  let tab_route = tab =>
    switch (tab) {
    | TSimulator => "simulator"
    | TSandbox => "sandbox"
    | TMolbuilder => "molbuilder"
    | TLogs => "logs"
    | TTests => "tests"
    };

  let tab_component = tab =>
    switch (tab) {
    | TSimulator => ((module SimulatorDummy): (module TAB_COMPONENT))
    | TSandbox => ((module Sandbox): (module TAB_COMPONENT))
    | TMolbuilder => ((module Molbuilder): (module TAB_COMPONENT))
    | TLogs => ((module Log_tree): (module TAB_COMPONENT))
    | TTests => ((module Tests.RenderApp): (module TAB_COMPONENT))
    };

  let route_matcher = route =>
    switch (route) {
    | ["simulator"] => TSimulator
    | ["sandbox"] => TSandbox
    | ["molbuilder"] => TMolbuilder
    | ["logs"] => TLogs
    | ["tests"] => TTests
    | _ => TSimulator
    };

  let tabs = [TSimulator, TSandbox, TMolbuilder, TLogs];

  let make_tab_data = tab => (tab, tab_name(tab)->React.string, tab_route(tab));
  let tabs_data = List.map(make_tab_data, tabs);

  [@react.component]
  let make = () => {
    let url = ReasonReactRouter.useUrl();
    let activeTab = route_matcher(url.path);
    module ActiveTabComp = (val tab_component(activeTab): TAB_COMPONENT);

    <Store.Provider store=Store.appStore>
      <div> <Components.Tabs2 tabs=tabs_data activeTab /> <div> <ActiveTabComp /> </div> </div>
    </Store.Provider>;
  };
};

ReactDOMRe.renderToElementWithId(<Main />, "app");
