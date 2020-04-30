open Client_utils;

module Tabs = {
  [@react.component]
  let make = (~tabs, ~activeTab, ~setActiveTab) => {
    let getClassName = t =>
      if (t == activeTab) {
        "is-active";
      } else {
        "";
      };

    <div className="tabs">
      <ul>
        {List.mapi(
           (i, (value, display)) =>
             <li className={getClassName(value)} key={string_of_int(i)}>
               <a onClick={_ => setActiveTab(value)}> display </a>
             </li>,
           tabs,
         )
         ->Generics.react_list}
      </ul>
    </div>;
  };
};

module NamedInput = {
  [@react.component]
  let make = (~label, ~value, ~setValue) => {
    <div className="field is-horizontal">
      <div className="field-label is-normal">
        <label className="label"> label->React.string </label>
      </div>
      <div className="field-body">
        <div className="field">
          <p className="control">
            <input
              className="input"
              value
              onChange={event => setValue(Generics.event_to_value(event))}
            />
          </p>
        </div>
      </div>
    </div>;
  };
};

module HFlex = {
  let hflex = Css.[display(flexBox)];

  [@react.component]
  let make = (~children, ~style) => {
    <div style={Css.style(hflex @ style)}> children </div>;
  };
};
