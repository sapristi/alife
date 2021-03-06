module Generics = {
  let useStateSimple = init => {
    let (state, setState) = React.useState(init);
    (
      state,
      state_reducer => {
        let new_state = state_reducer(state);
        /* Js.log4("Compare", new_state, state, new_state != state); */
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
  [@bs.send] external getElementById: (document, string) => domElement = "getElementById";
  [@bs.val] external doc: document = "document";
};

module Yaac = Utils__yaac;
module ArrayExt = Utils__ArrayExt;

type blob;
type blob_config = {. "type": string};
[@bs.new] external makeBlob: (array(string), blob_config) => blob = "Blob";

[@bs.module "file-saver"] external saveAs: (blob, string) => unit = "saveAs";

module BroadcastChannel = {
  type message = {data: string};
  type t = {
    .
    [@bs.set] "onmessage": option(message => unit),
    [@bs.meth] "postMessage": string => unit,
  };

  [@bs.new] external make: string => t = "BroadcastChannel";
};
