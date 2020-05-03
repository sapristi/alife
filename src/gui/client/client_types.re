[@decco]
type environment = {
  break_rate: string,
  collision_rate: string,
  grab_rate: string,
  transition_rate: string,
};

let default_env = {
  break_rate: "",
  collision_rate: "",
  grab_rate: "",
  transition_rate: "",
};

[@decco]
type active_mol = {
  qtt: int,
  mol: string,
};

[@decco]
type inert_mol = {
  qtt: int,
  mol: string,
  ambient: bool,
};

[@decco]
type bact = {
  active_mols: list(active_mol),
  inert_mols: list(inert_mol),
};

let default_bact = {active_mols: [], inert_mols: []};

[@decco]
type sandbox = {
  env: environment,
  bact,
};

let default_sandbox = {bact: default_bact, env: default_env};

type sandbox_action =
  | SetEnv(environment)
  | SetBact(bact)
  | SetSandbox(sandbox)
  | SetSelectedPnet(option((string, int)))
  | SwitchUpdate;

module Petri_net = {
  [@decco]
  type molecule = string;
  [@decco]
  type token = (int, molecule);

  [@decco]
  type acid_extension =
    | Grab_ext(string)
    | Release_ext
    | Init_with_token_ext;

  let acid_ext_to_cy = aext =>
    switch (aext) {
    | Grab_ext(s) => ("Grab_ext", s)
    | Release_ext => ("Release_ext", "")
    | Init_with_token_ext => ("Init_with_token_ext", "")
    };

  [@decco]
  type graber = string;

  [@decco]
  type place = {
    token: option(token),
    extensions: list(acid_extension),
    index: int,
    graber: option(graber),
  };

  [@decco]
  type input_arc_kind =
    | Regular_iarc
    | Split_iarc
    | Filter_iarc(string)
    | Filter_empty_iarc;

  let input_arc_to_cy = ia =>
    switch (ia) {
    | Regular_iarc => ("reg", "")
    | Split_iarc => ("split", "")
    | Filter_iarc(s) => ("filter", s)
    | Filter_empty_iarc => ("filter empty", {js|∅|js})
    };

  [@decco]
  type output_arc_kind =
    | Regular_oarc
    | Merge_oarc
    | Move_oarc(bool);

  let output_arc_to_cy = oa =>
    switch (oa) {
    | Regular_oarc => ("reg", "")
    | Merge_oarc => ("merge", "")
    | Move_oarc(b) => ("move", if (b) {{js|↷|js}} else {{js|↶|js}})
    };

  [@decco]
  type input_arc = {
    source_place: int,
    iatype: input_arc_kind,
  };
  [@decco]
  type output_arc = {
    dest_place: int,
    oatype: output_arc_kind,
  };

  [@decco]
  type transition = {
    id: string,
    input_arcs: list(input_arc),
    output_arcs: list(output_arc),
    index: int,
  };

  [@decco]
  type petri_net = {
    molecule,
    transitions: array(transition),
    places: array(place),
  };
};
