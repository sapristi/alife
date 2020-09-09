open Utils;
open Belt;

module Text = {
  [@react.component]
  let make =
      (
        ~value,
        ~setValue,
        ~multiline=false,
        ~styles=[],
        ~size=5,
        ~disabled=false,
      ) => {
    let (innerValue, setInnerValue) = React.useState(() => "");

    React.useEffect2(
      () => {
        setInnerValue(_ => value);
        None;
      },
      (value, setInnerValue),
    );

    let handleChange = event => {
      let v = event->Generics.event_to_value;
      setInnerValue(_ => v);
    };
    let commit = _ => {
      setValue(innerValue);
    };

    let inputStyle = Css.style(styles);

    if (multiline) {
      <textarea
        className="input"
        style=inputStyle
        type_="text"
        value=innerValue
        onChange=handleChange
        onBlur=commit
        disabled
      />;
    } else {
      <input
        className="input"
        style=inputStyle
        type_="text"
        value=innerValue
        onChange=handleChange
        onBlur=commit
        size
        disabled
      />;
    };
  };
};

module TextInline = {
  [@react.component]
  let make = (~value, ~setValue, ~style=[]) => {
    let (innerValue, setInnerValue) = React.useState(() => "");
    let (enabled, setEnabled) = React.useState(() => false);

    React.useEffect2(
      () => {
        setInnerValue(_ => value);
        None;
      },
      (value, setInnerValue),
    );

    let handleChange = event => {
      let v = event->Generics.event_to_value;
      setInnerValue(_ => v);
    };
    let commit = _ => {
      setValue(innerValue);
      setEnabled(_ => false);
    };

    let buttonStyle =
      ReactDOMRe.Style.make(
        ~padding="0px",
        ~height="1.5em",
        ~paddingLeft="2px",
        (),
      );

    if (enabled) {
      <input
        autoFocus=true
        className="input"
        style={Css.style(style)}
        type_="text"
        value=innerValue
        onChange=handleChange
        onBlur=commit
      />;
    } else {
      <Components__flex.HFlex
        style=Css.[
          border(px(1), `solid, lightgrey),
          borderRadius(px(4)),
          padding(px(1)),
        ]>
        value->React.string
        <button
          style=buttonStyle
          className="button"
          onClick={_ => setEnabled(_ => true)}>
          <Components__icons.Edit size=18 />
        </button>
      </Components__flex.HFlex>;
    };
  };
};

module Select = {
  [@react.component]
  let make = (~options, ~initValue, ~setValue, ~modifiers=[]) => {
    let handleChange = event => {
      let v = event->Generics.event_to_value;
      setValue(_ => v);
    };

    <div className=Cn.("select" + fromList(modifiers))>
      <select value=initValue onChange=handleChange>
        {List.map(options, ((value, text)) =>
           <option value key=value> text->React.string </option>
         )
         ->Generics.react_list}
      </select>
    </div>;
  };
};

module Checkbox = {
  [@react.component]
  let make = (~state, ~setState, ~id, ~label) => {
    let toggle = _ => setState(prev => !prev);
    <div style=Css.(style([alignItems(`center), display(`flex)]))>
      <input htmlFor=id type_="checkbox" onChange=toggle checked=state />
      <label
        className="checkbox"
        onClick=toggle
        id
        style=Css.(style([fontSize(`initial), fontWeight(`initial)]))>
        label->React.string
      </label>
    </div>;
  };
};
