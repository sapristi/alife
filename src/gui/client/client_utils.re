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
           Js.log(("Got from " ++ endpoint, json));
           callback(json);
         }
         |> resolve
       )
  );
};

let useStateSimple = init => {
  let (state, setState) = React.useState(init);
  (
    state,
    state_reducer => {
      let new_state = state_reducer(state);
      Js.log(("Compare", new_state, state));
      if (new_state == state) {
        setState(_ => state);
      } else {
        setState(_ => new_state);
      };
    },
  );
};
/* [@bs.module "./semantic_binds"] external dropdown: string => unit = "dropdown"; */
/* [@bs.val] external dropdown: string => unit = "dropdown"; */

type document;
type domElement = {dropdown: unit => unit};
[@bs.send]
external getElementById: (document, string) => domElement = "getElementById";
[@bs.val] external doc: document = "document";

module Icons = MscharleyBsMaterialUiIcons;
