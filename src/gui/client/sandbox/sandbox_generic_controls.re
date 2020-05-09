open Client_utils;

module EnvControls = {
  [@react.component]
  let make = (~env: Client_types.environment, ~dispatch) => {
    let (innerEnv, setInnerEnv) = Generics.useStateSimple(() => env);

    let commit = _ => {
      YaacApi.request(
        Fetch.Put,
        "/api/sandbox/environment",
        ~payload=Client_types.environment_encode(innerEnv),
        ~json_decode=Client_types.environment_decode,
        ~callback=new_env => dispatch(Client_types.SetEnv(new_env)),
        (),
      )
      ->ignore;
    };

    React.useEffect1(
      () => {
        setInnerEnv(_ => env);
        None;
      },
      [|env|],
    );

    <div className="tile is-vertical box">
      <Components.NamedInput
        label="break rate"
        value={innerEnv.break_rate}
        setValue={new_value => setInnerEnv(_ => {...innerEnv, break_rate: new_value})}
      />
      <Components.NamedInput
        label="grab rate"
        value={innerEnv.grab_rate}
        setValue={new_value => setInnerEnv(_ => {...innerEnv, grab_rate: new_value})}
      />
      <Components.NamedInput
        label="transition rate"
        value={innerEnv.transition_rate}
        setValue={new_value => setInnerEnv(_ => {...innerEnv, transition_rate: new_value})}
      />
      <Components.NamedInput
        label="collision rate"
        value={innerEnv.collision_rate}
        setValue={new_value => setInnerEnv(_ => {...innerEnv, collision_rate: new_value})}
      />
      <div className="buttons has-addons">
        <button className="button" onClick=commit> "Commit"->React.string </button>
        <button className="button" onClick={_ => setInnerEnv(_ => env)}> "Reset"->React.string </button>
      </div>
    </div>;
  };
};

module StateControls = {
  module StateLoader = {
    [@decco]
    type data = list(string);

    [@react.component]
    let make = (~update) => {
      let (values, setValues) = React.useState(_ => []);

      React.useEffect0(() => {
        YaacApi.request(
          Fetch.Get,
          "/sandbox/state",
          ~json_decode=data_decode,
          ~callback=data => setValues(_ => data),
          (),
        )
        ->ignore;
        None;
      });
      let (state, setState) = React.useReducer((_, v) => v, "");

      let commit = _ => YaacApi.request(Fetch.Put, "/sandbox/state/" ++ state, ~side_effect=update, ())->ignore;

      <div>
        <div className="select">
          <select value=state onChange={e => setState(Generics.event_to_value(e))}>
            {List.map(v => <option value=v key=v> {React.string(v)} </option>, values)->Generics.react_list}
          </select>
        </div>
        <button className="ui primary button" onClick=commit> {React.string("Load state")} </button>
      </div>;
    };
  };

  [@react.component]
  let make = (~update) => {
    <div className="tile is-vertical box" style=Css.(style([justifyContent(spaceEvenly)]))>
      <div>
        <div className="buttons has-addons">
          /* <Tooltip title={<Typography> "update" </Typography>}> */

            <button className="button"> "Refresh"->React.string </button>
            /* </Tooltip> */
            /* <Tooltip */
            /*   title={<Typography> "Reset sandbox to initial state" </Typography>}> */
            <button className="button"> "Reset"->React.string </button>
            /* </Tooltip> */
            <button className="button"> "Load from file"->React.string </button>
            <button className="button"> "Reset"->React.string </button>
          </div>
      </div>
      <StateLoader update />
      <Components.HFlex style=[]>
        <input className="input" type_="text" placeholder="Random seed" />
        <button className="button"> {React.string("Commit Seed")} </button>
      </Components.HFlex>
    </div>;
  };
};

[@react.component]
let make = (~env, ~update, ~dispatch) => {
  <div className="tile"> <StateControls update /> <EnvControls env dispatch /> </div>;
};
