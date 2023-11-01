module S = {
  module Molbuilder = Store__molbuilder;
};

type appState = {
  molbuilder: S.Molbuilder.state,
  pendingRequest: bool,
};

let app_init_state = {
  molbuilder: S.Molbuilder.init_state,
  pendingRequest: false,
};
type appAction =
  | MolBuilderAction(S.Molbuilder.action)
  | SetPending(bool);

let appReducer = (state: appState, action: appAction) => {
  switch (action) {
  | MolBuilderAction(mbaction) => {
      ...state,
      molbuilder: S.Molbuilder.reducer(state.molbuilder, mbaction),
    }
  | SetPending(v) => {...state, pendingRequest: v}
  };
};
let appStore =
  Reductive.Store.create(
    ~reducer=appReducer,
    ~preloadedState=app_init_state,
    (),
  );

include ReductiveContext.Make({
  type action = appAction;
  type state = appState;
});
