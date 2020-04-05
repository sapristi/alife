[%raw "require('isomorphic-fetch')"];
[%raw "require('typeface-roboto')"];
open MaterialUi;

module Main = {
  [@react.component]
  let make = () => {
    let (value, setValue) = React.useReducer((_, v) => v, 1);

    let handleChange = (_, newValue: int) => {
      setValue(newValue);
    };
    <div>
      <AppBar position=`Static>
        <Tabs value onChange=handleChange>
          <Tab label={"Simulator"->React.string} />
          <Tab label={"Sandbox"->React.string} />
          <Tab label={"Molbuilder"->React.string} />
        </Tabs>
      </AppBar>
      <div style={ReactDOMRe.Style.make(~paddingTop="40px", ())}>
        {switch (value) {
         | 0 => React.string("Simulator")
         | 1 => <Sandbox />
         | _ => React.string("Molbuilder")
         }}
      </div>
    </div>;
  };
};

ReactDOMRe.renderToElementWithId(<Main />, "app");
