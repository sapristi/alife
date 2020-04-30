module YaacApi = {
  let origin = "http://localhost:1512";
  /* [%raw {|import {dropdown} require('./semantic_binds')|}]; */
  [@bs.module "path"] external dirname: string => string = "dirname";

  let get = (endpoint, callback) => {
    Js.log("Requesting " ++ endpoint);
    Js.Promise.(
      Fetch.fetchWithInit(
        origin ++ endpoint,
        Fetch.RequestInit.make(~method_=Get, ()),
      )
      |> then_(Fetch.Response.json)
      |> then_(json =>
           {
             Js.log2("Got from " ++ endpoint, json);
             callback(json);
           }
           |> resolve
         )
    );
  };

  let put = (endpoint, payload, ~callback) => {
    let body = Fetch.BodyInit.make(Js.Json.stringify(payload));
    Js.log2("Requesting " ++ endpoint, body);
    Js.Promise.(
      Fetch.fetchWithInit(
        origin ++ endpoint,
        Fetch.RequestInit.make(~method_=Put, ~body, ()),
      )
      |> then_(Fetch.Response.json)
      |> then_(json =>
           {
             Js.log2("Got from " ++ endpoint, json);
             switch (callback) {
             | None => ()
             | Some(callback) => callback(json)
             };
           }
           |> resolve
         )
    );
  };
};

module Generics = {
  let useStateSimple = init => {
    let (state, setState) = React.useState(init);
    (
      state,
      state_reducer => {
        let new_state = state_reducer(state);
        Js.log(("Compare", new_state, state));
        if (new_state != state) {
          setState(_ => new_state);
        };
      },
    );
  };
  let react_list = l => ReasonReact.array(Array.of_list(l));
  let event_to_value = event => ReactEvent.Form.target(event)##value;
};
/* [@bs.module "./semantic_binds"] external dropdown: string => unit = "dropdown"; */
/* [@bs.val] external dropdown: string => unit = "dropdown"; */

module MiscTries = {
  type document;
  type domElement = {dropdown: unit => unit};
  [@bs.send]
  external getElementById: (document, string) => domElement = "getElementById";
  [@bs.val] external doc: document = "document";
};
