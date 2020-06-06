open Utils;
open Belt;

module Text = {
  [@react.component]
  let make = (~value, ~setValue, ~style=?) => {
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
      setValue(_ => innerValue);
    };

    let inputStyle = style->Option.getWithDefault(ReactDOMRe.Style.make());

    <input className="input" style=inputStyle type_="text" value=innerValue onChange=handleChange onBlur=commit />;
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

    let buttonStyle = ReactDOMRe.Style.make(~padding="0px", ~height="1.5em", ~paddingLeft="2px", ());

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
        style=Css.[border(px(1), `solid, lightgrey), borderRadius(px(4)), padding(px(1))]>
        value->React.string
        <button style=buttonStyle className="button" onClick={_ => setEnabled(_ => true)}>
          <Components__icons.EditIcon />
        </button>
      </Components__flex.HFlex>;
    };
  };
};

module Select = {
  [@react.component]
  let make = (~options, ~initValue, ~setValue) => {
    let handleChange = event => {
      let v = event->Generics.event_to_value;
      setValue(_ => v);
    };

    <div className="select">
      <select value=initValue onChange=handleChange>
        {List.map(options, ((value, text)) => <option value> text->React.string </option>)->Generics.react_list}
      </select>
    </div>;
  };
};
