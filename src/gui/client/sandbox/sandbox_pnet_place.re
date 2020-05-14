open Types;
open Utils;

module TokenComponent = {
  let token_separator =
    <font className=Css.(style([color(red), fontWeight(bold)]))> {js|►|js}->React.string </font>;

  let token_to_parts = ((i, mol)) => {
    (String.sub(mol, 0, i), String.sub(mol, i, mol->String.length - i));
  };

  let token_to_elem = token =>
    switch (token) {
    | None => <span />
    | Some((i, mol)) =>
      let (a, b) = token_to_parts((i, mol));
      <span> {a}->React.string token_separator {b}->React.string </span>;
    };
  [@react.component]
  let make = (~token) => {
    let (editable, setEditable) = React.useState(() => false);
    let (innerToken, setInnerToken) = React.useState(() => token);

    let (tokenParts, setTokenParts) = React.useState(() => Belt.Option.map(token, token_to_parts));

    <div className="message is-info">
      <div className="message-header"> "Token"->React.string </div>
      <div className="message-body">
        <label className="checkbox">
          <input type_="checkbox" value={editable->string_of_bool} onChange={_ => setEditable(p => !p)} />
          "Editable"->React.string
        </label>
        <div className="control">
          <label className="radio">
            <input
              type_="radio"
              name="answer"
              disabled={!editable}
              checked={Belt.Option.isNone(innerToken)}
              onChange={_ => setInnerToken(_ => None)}
            />
            "No token"->React.string
          </label>
          <label className="radio">
            <input
              type_="radio"
              name="answer"
              disabled={!editable}
              checked={Belt.Option.isSome(innerToken)}
              onChange={_ => setInnerToken(_ => Some((0, "")))}
            />
            "Token"->React.string
          </label>
        </div>
        {token_to_elem(innerToken)}
        {switch (tokenParts) {
         | None => React.null
         | Some((a, b)) =>
           <div>
             <input className="input" type_="text" value=a />
             <input className="input" type_="text" value=b />
           </div>
         }}
      </div>
    </div>;
  };
};

[@react.component]
let make = (~pnet: Petri_net.t, ~place_id) => {
  let place = pnet.places[place_id];
  let place_body =
    switch (place.extensions) {
    | [] => "No extensions"->React.string
    | _ =>
      <React.Fragment>
        "Extensions:"->React.string
        <ul>
          {List.map(
             e => {
               let d = Client_types.Chemistry.place_ext_to_descr(e);
               <li key=d> d->React.string </li>;
             },
             place.extensions,
           )
           ->Generics.react_list}
        </ul>
      </React.Fragment>
    };
  <div>
    <div className="message is-info">
      <div className="message-header"> "Place"->React.string </div>
      <div className="message-body content"> place_body </div>
    </div>
    <TokenComponent token={place.token} />
  </div>;
};
