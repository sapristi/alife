open Utils;
open Components;
open Belt;
module EnvControls = Sandbox__generic_controls__env_controls;
module StateForm = Sandbox__generic_controls__state_form;

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

module StatesTable = {
  [@decco]
  type data_item = {
    name: string,
    description: string,
    time: string,
  };
  [@decco]
  type data = array(data_item);

  let makeColumns = (loadAction): array(Table.column(data_item)) => [|
    {
      style: [],
      header: () => "Name"->React.string,
      makeCell: row => row.name->React.string,
      key: "name",
    },
    {
      style: [],
      header: () => "Description"->React.string,
      makeCell: row => row.description->React.string,
      key: "decription",
    },
    {
      style: [],
      header: () => "Actions"->React.string,
      makeCell: row =>
        <Button onClick={_ => loadAction(row.name)}> "Load"->React.string </Button>,
      key: "action",
    },
  |];

  let getRowKey = row => row.name;

  [@react.component]
  let make = (~update) => {
    let (values, setValues) = React.useState(_ => [||]);

    let commitLoad =
      React.useCallback1(
        name =>
          Yaac.request_unit(Fetch.Post, "/sandbox/state/" ++ name ++ "/load", ())
          ->Promise.getOk(update),
        [|update|],
      );

    let columns = makeColumns(commitLoad);

    React.useEffect0(() => {
      Yaac.request(Fetch.Get, "/sandbox/state", ~json_decode=data_decode, ())
      ->Promise.getOk(data => {setValues(_ => data)});
      None;
    });

    <div style=Css.(style([maxHeight(px(300)), overflow(auto)]))>
      <Table columns data=values getRowKey />
    </div>;
  };
};

[@react.component]
let make = (~env, ~seed, ~update, ~dispatch) => {
  let (showDialog, setShowDialog) = React.useState(() => false);
  let (innerEnv, setInnerEnv) = React.useState(() => env);
  let (innerSeed, setInnerSeed) = React.useState(() => seed);
  React.useEffect1(
    () => {
      setInnerEnv(_ => env);
      None;
    },
    [|env|],
  );

  <HFlex className="tile">
    <Modal isOpen=showDialog onRequestClose={_ => setShowDialog(_ => false)}>
      <StateForm env seed />
    </Modal>
    <VFlex className="box" style=Css.[marginBottom(px(0)), width(pct(50.))]>
      <h5 className="title nice-title is-5"> "Predefined states"->React.string </h5>
      <StatesTable update />
    </VFlex>
    <VFlex className="box" style=Css.[width(pct(50.))]>
      <h5 className="title nice-title is-5"> "Runtime environment"->React.string </h5>
      <EnvControls env=innerEnv setEnv=setInnerEnv />
      <Input.NamedInput label="Random seed">
        <Input.Text
          value={innerSeed->string_of_int}
          onChange={new_seed => setInnerSeed(_ => int_of_string(new_seed))}
        />
      </Input.NamedInput>
      <div className="buttons has-addons">
        <Button onClick={_ => commitEnv(innerEnv, dispatch)}> "Commit"->React.string </Button>
        <Button onClick={_ => setInnerEnv(_ => env)}> "Reset"->React.string </Button>
        <Button onClick={_ => setShowDialog(_ => true)}> "CLICK"->React.string </Button>
      </div>
    </VFlex>
  </HFlex>;
};
