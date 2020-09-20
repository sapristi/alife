open Utils;
open Belt;
module Text = {
  [@react.component]
  let make =
    React.forwardRef(
      (
        ~value,
        ~onChange,
        ~multiline=false,
        ~styles=[],
        ~size=5,
        ~disabled=false,
        ~onBlur=_ => (),
        ~autoFocus=false,
        ref_,
      ) => {
      let handleChange = event => {
        let v = event->Generics.event_to_value;
        onChange(v);
      };

      let inputStyle = Css.style(styles);
      if (multiline) {
        <textarea
          className="input"
          style=inputStyle
          type_="text"
          value
          onChange=handleChange
          disabled
          onBlur
          autoFocus
          rows=size
          ref=?{
            Js.Nullable.toOption(ref_)
            ->Belt.Option.map(ReactDOMRe.Ref.domRef)
          }
        />;
      } else {
        <input
          className="input"
          style=inputStyle
          type_="text"
          value
          onChange=handleChange
          size
          disabled
          onBlur
          autoFocus
          ref=?{
            Js.Nullable.toOption(ref_)
            ->Belt.Option.map(ReactDOMRe.Ref.domRef)
          }
        />;
      };
    });
};

module TextInline = {
  [@react.component]
  let make =
      (~value, ~setValue: string => unit, ~styles=[], ~multiline=false, ~size=4) => {
    let (innerValue, setInnerValue) = React.useState(() => "");
    let (enabled, setEnabled) = React.useState(() => false);

    React.useEffect2(
      () => {
        setInnerValue(_ => value);
        None;
      },
      (value, setInnerValue),
    );
    let inputRef = React.useRef(Js.Nullable.null);
    let handleChange = v => {
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
    let onClick = _ => {
      setEnabled(_ => true);
      Js.Global.setTimeout(
        () =>
          inputRef.current
          ->Js.Nullable.toOption
          ->Option.forEach(e => e##focus()),
        50,
      )
      ->ignore;
    };

    <Components__flex.HFlex
      style=Css.[
        border(px(1), `solid, lightgrey),
        borderRadius(px(4)),
        padding(px(1)),
        justifyContent(spaceBetween),
      ]>
      <Text
        autoFocus=true
        styles
        value=innerValue
        onChange=handleChange
        onBlur=commit
        multiline
        disabled={!enabled}
        ref=inputRef
        size
      />
      <button style=buttonStyle className="button" onClick>
        <Components__icons.Edit size=18 />
      </button>
    </Components__flex.HFlex>;
  };
};

module Select = {
  [@react.component]
  let make = (~options, ~value, ~onChange, ~modifiers=[]) => {
    let handleChange = event => {
      let v = event->Generics.event_to_value;
      onChange(v);
    };

    <div className=Cn.("select" + fromList(modifiers))>
      <select value onChange=handleChange>
        {Array.map(options, ((value, text)) =>
           <option value key=value> text->React.string </option>
         )
         ->React.array}
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
