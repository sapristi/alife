[@decco]
type environment = {
  break_rate: string,
  collision_rate: string,
  grab_rate: string,
  transition_rate: string,
};
let default_env = {break_rate: "", collision_rate: "", grab_rate: "", transition_rate: ""};

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

[@decco]
type pnet_action =
  | Update_token(option(Types.Token.t), int)
  | Launch_transition(int);

module Chemistry = {
  open Acid_types;
  let place_ext_to_cy = aext =>
    switch (aext) {
    | Grab_ext(s) => ("Grab_ext", s)
    | Release_ext => ("Release_ext", "")
    | Init_with_token_ext => ("Init_with_token_ext", "")
    };
  let place_ext_to_descr = aext =>
    switch (aext) {
    | Grab_ext(s) => "Grab (" ++ s ++ ")"
    | Release_ext => "Release incoming token"
    | Init_with_token_ext => "Init with token"
    };
  let input_arc_to_cy = ia =>
    switch (ia) {
    | Regular_iarc => ("reg", "")
    | Split_iarc => ("split", "")
    | Filter_iarc(s) => ("filter", s)
    | Filter_empty_iarc => ("filter empty", {js|∅|js})
    };
  let input_arc_to_descr = ia =>
    switch (ia) {
    | Regular_iarc => "regular"
    | Split_iarc => "split"
    | Filter_iarc(s) => "filter (" ++ s ++ ")"
    | Filter_empty_iarc => "filter empty"
    };
  let output_arc_to_cy = oa =>
    switch (oa) {
    | Regular_oarc => ("reg", "")
    | Merge_oarc => ("merge", "")
    | Move_oarc(b) => ("move", if (b) {{js|↷|js}} else {{js|↶|js}})
    };
  let output_arc_to_descr = oa =>
    switch (oa) {
    | Regular_oarc => "regular"
    | Merge_oarc => "merge"
    | Move_oarc(b) => "move " ++ (if (b) {"forward"} else {"backward"})
    };
  [@decco];

  let acid_to_descr = a =>
    switch (a) {
    | Place => "Place"
    | InputArc(ia_id, ia_type) => input_arc_to_descr(ia_type) ++ "; " ++ ia_id
    | OutputArc(oa_id, oa_type) => output_arc_to_descr(oa_type) ++ "; " ++ oa_id
    | Extension(ext) => place_ext_to_descr(ext)
    };
};
