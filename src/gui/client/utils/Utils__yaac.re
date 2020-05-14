let origin = "http://localhost:1512/api";
/* [%raw {|import {dropdown} require('./semantic_binds')|}]; */
[@bs.module "path"] external dirname: string => string = "dirname";

let get = (endpoint, callback) => {
  Js.log("Requesting " ++ endpoint);
  Js.Promise.(
    Fetch.fetchWithInit(origin ++ endpoint, Fetch.RequestInit.make(~method_=Get, ()))
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

let handle_ok_response = (response, json_decode, callback, side_effect, ko_callback: unit => unit) => {
  let after =
    switch (side_effect) {
    | None => (() => ())
    | Some(action) => action
    };
  switch (json_decode, callback) {
  | (Some(json_decode'), Some(callback')) =>
    response
    |> Fetch.Response.json
    |> Js.Promise.then_(response_json => {
         Js.log2("Received", response_json);
         switch (json_decode'(response_json)) {
         | Ok(x_decoded) =>
           callback'(x_decoded);
           after() |> Js.Promise.resolve;
         | Error(e) =>
           Js.log3("Could not decode", response_json, e);
           ko_callback() |> Js.Promise.resolve;
         };
       })
  | _ =>
    (response |> Fetch.Response.json |> Js.Promise.then_(json => Js.log2("Received", json) |> Js.Promise.resolve))
    ->ignore;
    after() |> Js.Promise.resolve;
  };
};

let request = (method_, endpoint, ~payload=?, ~json_decode=?, ~callback=?, ~ko_callback=?, ~side_effect=?, ()) => {
  let ko_callback' =
    switch (ko_callback) {
    | Some(ko_callback') => ko_callback'
    | None => (() => ())
    };
  let request =
    switch (payload) {
    | None => Fetch.RequestInit.make(~method_, ())
    | Some(r) =>
      let body = Fetch.BodyInit.make(Js.Json.stringify(r));
      Fetch.RequestInit.make(~method_, ~body, ());
    };

  Js.log("Requesting " ++ endpoint);
  Js.Promise.(
    Fetch.fetchWithInit(origin ++ endpoint, request)
    |> then_(response =>
         if (Fetch.Response.ok(response)) {
           handle_ok_response(response, json_decode, callback, side_effect, ko_callback');
         } else {
           {
             Js.log("Error from " ++ endpoint);
             ko_callback'();
           }
           |> resolve;
         }
       )
  );
};
