open Utils;
open Components;
open Belt;

module Signatures = Sandbox__generic_controls__signatures;
module Dumps = Sandbox__generic_controls__dumps;

module Runtime_controls = {
  module EnvControls = Sandbox__generic_controls__env_controls;
  let commitEnv = (env, dispatch) => {
    Yaac.request(
      Fetch.Put,
      "/sandbox/environment",
      ~payload=Client_types.environment_encode(env),
      ~json_decode=Client_types.environment_decode,
      (),
    )
    ->Promise.getOk(new_env => dispatch(Client_types.SetEnv(new_env)));
  };

  [@react.component]
  let make = (~env, ~seed, ~update, ~dispatch) => {
    let (innerEnv, setInnerEnv) = React.useState(() => env);
    let (innerSeed, setInnerSeed) = React.useState(() => seed);

    React.useEffect1(
      () => {
        setInnerEnv(_ => env);
        None;
      },
      [|env|],
    );
    <HFlex>
      <VFlex className="box" style=Css.[width(pct(50.))]>
        <h5 className="title nice-title is-5"> "Environment"->React.string </h5>
        <EnvControls env=innerEnv setEnv=setInnerEnv />
        <div className="buttons has-addons">
          <Button onClick={_ => commitEnv(innerEnv, dispatch)}> "Commit"->React.string </Button>
          <Button onClick={_ => setInnerEnv(_ => env)}> "Reset"->React.string </Button>
        </div>
      </VFlex>
      <VFlex className="box" style=Css.[width(pct(50.))]>
        <Input.NamedInput label="Random seed">
          <Input.Text
            value={innerSeed->string_of_int}
            onChange={new_seed => setInnerSeed(_ => int_of_string(new_seed))}
          />
        </Input.NamedInput>
        <div className="buttons has-addons">
          <Button> "Commit"->React.string </Button>
          <Button> "Reset"->React.string </Button>
        </div>
      </VFlex>
    </HFlex>;
  };
};

type tab =
  | SSigs
  | SDumps
  | Runtime;

let tabs = [|
  (SSigs, "Sandbox signatures"),
  (SDumps, "Sandbox dumps"),
  (Runtime, "Runtime controls"),
|];

[@react.component]
let make = (~env, ~seed, ~update, ~dispatch) => {
  let (activeTab, setActiveTab) = React.useReducer((_, v) => v, SSigs);

  <React.Fragment>
    <Panel.Tabs tabs activeTab setActiveTab />
    {switch (activeTab) {
     | SSigs => <Signatures update env seed />
     | SDumps => <Dumps update />
     | Runtime => <Runtime_controls update env seed dispatch />
     }}
  </React.Fragment>;
};
