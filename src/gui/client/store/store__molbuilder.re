open Client_types;

type state = {
  mol: Types.Molecule.t,
  pnet: option(Types.Petri_net.t),
  proteine,
};

let init_state = {mol: "", pnet: None, proteine: [||]};

type action =
  | Set(state);

let reducer = (state: state, action: action): state => {
  switch (action) {
  | Set(new_state) => new_state
  };
};
