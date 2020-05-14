open Utils;
open Belt;

module Text = {
  [@react.component]
  let make = (~value, ~setValue) => {
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

    <input className="input" type_="text" value=innerValue onChange=handleChange onBlur=commit />;
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
