let origin = "http://localhost:1512/api";
[@bs.module "path"] external dirname: string => string = "dirname";

open Store;

let request = (method_, endpoint, ~payload=?, ~json_decode, ()) => {
  let request =
    switch (payload) {
    | None => Fetch.RequestInit.make(~method_, ())
    | Some(r) =>
      let body = Fetch.BodyInit.make(Js.Json.stringify(r));
      Fetch.RequestInit.make(~method_, ~body, ());
    };

  Reductive.Store.dispatch(Store.appStore, Store.SetPending(true));
  Js.log("Requesting " ++ endpoint);
  (
    Fetch.fetchWithInit(origin ++ endpoint, request)
    |> Js.Promise.then_(Fetch.Response.json)
  )
  ->Promise.Js.fromBsPromise
  ->Promise.Js.toResult
  ->Promise.map(response => {
      Reductive.Store.dispatch(Store.appStore, Store.SetPending(false));
      switch (response) {
      | Ok(response') =>
        Js.log2("Received", response');
        switch (json_decode(response')) {
        | Ok(x_decoded) => Ok(x_decoded)
        | Error(e) =>
          Js.log3("Could not decode", response, e);
          Error();
        };
      | Error(e) =>
        Js.log("Error from " ++ endpoint);
        Error();
      };
    });
};

let request_unit = (method_, endpoint, ~payload=?, ()) => {
  let request =
    switch (payload) {
    | None => Fetch.RequestInit.make(~method_, ())
    | Some(r) =>
      let body = Fetch.BodyInit.make(Js.Json.stringify(r));
      Fetch.RequestInit.make(~method_, ~body, ());
    };

  Js.log("Requesting " ++ endpoint);
  Fetch.fetchWithInit(origin ++ endpoint, request)
  ->Promise.Js.fromBsPromise
  ->Promise.Js.toResult
  ->Promise.map(response =>
      switch (response) {
      | Ok(response') =>
        if (Fetch.Response.ok(response')) {
          Ok();
        } else {
          Error();
        }
      | Error(e) =>
        Js.log("Error from " ++ endpoint);
        Error();
      }
    );
};
