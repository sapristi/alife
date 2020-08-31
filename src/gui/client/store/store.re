module S = {
  module Molbuilder = Store__molbuilder;
};

type appState = {molbuilder: S.Molbuilder.state};

let app_init_state = {molbuilder: S.Molbuilder.init_state};
type appAction =
  | MolBuilderAction(S.Molbuilder.action);

let appReducer = (state: appState, action: appAction) => {
  switch (action) {
  | MolBuilderAction(mbaction) => {
      molbuilder: S.Molbuilder.reducer(state.molbuilder, mbaction),
    }
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
