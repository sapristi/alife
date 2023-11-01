/*
 * Example using multiple components to represent different slices of state.
 * Updating the state exposed by one component should not cause the other
 * components to also update (visually). Use the React Devtools "highlight
 * updates" feature to see this in action. If that proves difficult, then
 * try the Chrome devtools Rendering options, enabling "Paint flashing".
 */
type counterAction =
  | Increment
  | Decrement;

let counterReduce = (state, action) =>
  switch (action) {
  | Increment => state + 1
  | Decrement => state - 1
  };

module ReduxThunk = {
  type thunk('state) = ..;

  type thunk('state) +=
    | Thunk((Reductive.Store.t(thunk('state), 'state) => unit));
};

type ReduxThunk.thunk(_) +=
  | CounterAction(counterAction);

type appState = {
  counter: int,
  content: string,
};

let appReducer = (state, action) =>
  switch (action) {
  | CounterAction(action) => {
      ...state,
      counter: counterReduce(state.counter, action),
    }
  | _ => state
  };

module Middleware = {
  let logger = (store, next, action) => {
    Js.log(action);
    let returnValue = next(action);
    Js.log(Reductive.Store.getState(store));
    returnValue;
  };

  /***
   * middleware that listens for a specific action and calls that function.
   * Allows for async actions.
   */
  let thunk = (store, next, action) =>
    switch (action) {
    | ReduxThunk.Thunk(func) => func(store)
    | _ => next(action)
    };
};

let thunkedLogger = (store, next) =>
  Middleware.thunk(store) @@ Middleware.logger(store) @@ next;

let appStore =
  Reductive.Store.create(
    ~reducer=appReducer,
    ~preloadedState={counter: 0, content: ""},
    ~enhancer=thunkedLogger,
    (),
  );

module AppStore = {
  include ReductiveContext.Make({
    type state = appState;
    type action = ReduxThunk.thunk(appState);
  });
};

let counterSelector = state => state.counter;

let make_promise_handler = prom => {
  ReduxThunk.Thunk(
    store =>
      prom
      |> Js.Promise.then_(res_action =>
           Reductive.Store.dispatch(store, res_action) |> Js.Promise.resolve
         )
      |> ignore,
  );
};

module CounterComponent = {
  [@react.component]
  let make = () => {
    let dispatch = AppStore.useDispatch();
    let state = AppStore.useSelector(counterSelector);

    <div>
      <div> {ReasonReact.string("Counter: " ++ string_of_int(state))} </div>
      <button onClick={_ => dispatch(CounterAction(Increment))}>
        {ReasonReact.string("++")}
      </button>
      <button onClick={_ => dispatch(CounterAction(Decrement))}>
        {ReasonReact.string("--")}
      </button>
      <button
        onClick={_ =>
          dispatch(
            make_promise_handler(
              CounterAction(Decrement) |> Js.Promise.resolve,
            ),
          )
        }>
        {ReasonReact.string("??")}
      </button>
    </div>;
  };
};

module RenderApp = {
  [@react.component]
  let make = () => {
    <AppStore.Provider store=appStore>
      <div> <CounterComponent /> </div>
    </AppStore.Provider>;
  };
};
