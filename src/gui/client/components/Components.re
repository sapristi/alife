open Utils;

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
              onChange={event => {
                let new_value = Generics.event_to_value(event);
                setValue(new_value);
              }}
            />
          </p>
        </div>
      </div>
    </div>;
  };
};

module HFlex = Components__flex.HFlex;
module VFlex = Components__flex.VFlex;

module Yaac = Utils__yaac;
module ArrayExt = Utils__ArrayExt;

module Input = Components__input;

module Icons = Components__icons;
module Panel = Components__panel;
