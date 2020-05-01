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
  | SetSandbox(sandbox);
