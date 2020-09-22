open Utils;
open Components;
open Belt;
module EnvControls = Sandbox__generic_controls__env_controls;

module StateLoader = {
  [@decco]
  type data_item = {
    name: string,
    description: string,
    time: string,
  };
  [@decco]
  type data = array(data_item);

  let get_value_by_name = (name, values) =>
    Array.getBy(values, value => value.name === name)->Option.getExn;

  [@react.component]
  let make = (~update, ~currentValue, ~setCurrentValue) => {
    let (values, setValues) = React.useState(_ => [||]);

    React.useEffect0(() => {
      Yaac.request(Fetch.Get, "/sandbox/state", ~json_decode=data_decode, ())
      ->Promise.getOk(data => {
          setValues(_ => data);
          setCurrentValue(_ => Array.getExn(data, 0));
        });
      None;
    });

    let commitLoad = _ =>
      Yaac.request_unit(
        Fetch.Post,
        "/sandbox/state/" ++ currentValue.name ++ "/load",
        (),
      )
      ->Promise.getOk(update);

    <div>
      <Input.Select
        options={Array.map(values, v => (v.name, v.name))}
        value={currentValue.name}
        onChange={new_value =>
          setCurrentValue(_ => get_value_by_name(new_value, values))
        }
      />
      <button className="ui primary button" onClick=commitLoad>
        {React.string("Load state")}
      </button>
    </div>;
  };
};

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
  let (currentValue, setCurrentValue) =
    React.useState(() => {StateLoader.name: "", description: "", time: ""});

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
    <Modal isOpen=showDialog onRequestClose={_ => setShowDialog(_ => false)}

        style=({
    overlay: [],
    content: Css.([width(px(200))])
  }: Modal.style)
        >
      <div> "OKOKAPOJEPOAJZPOAJZPOAJZPO"->React.string </div>
    </Modal>
    <VFlex
      className="box" style=Css.[marginBottom(px(0)), width(pct(50.))]>
      <h5 className="title nice-title is-5">
        "Predefined states"->React.string
      </h5>
      <StateLoader update currentValue setCurrentValue />
      "Description:"->React.string
      <Input.TextInline
        value={currentValue.description}
        setValue={new_description =>
          setCurrentValue(prev => {...prev, description: new_description})
        }
        multiline=true
        size=10
      />
      "Seed"->React.string
      <Input.TextInline
        value={innerSeed->string_of_int}
        setValue={new_seed => setInnerSeed(_ => int_of_string(new_seed))}
      />
    </VFlex>
    <VFlex className="box">
      <h5 className="title nice-title is-5">
        "Runtime environment"->React.string
      </h5>
      <EnvControls env=innerEnv setEnv=setInnerEnv />
      <div className="buttons has-addons">
        <Button onClick={_ => commitEnv(innerEnv, dispatch)}>
          "Commit"->React.string
        </Button>
        <Button onClick={_ => setInnerEnv(_ => env)}>
          "Reset"->React.string
        </Button>
        <Button onClick={_ => setShowDialog(_ => true)}>
          "CLICK"->React.string
        </Button>
      </div>
    </VFlex>
  </HFlex>;
};
