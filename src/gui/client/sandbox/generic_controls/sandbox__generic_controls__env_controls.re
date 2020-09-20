open Utils;

[@react.component]
let make = (~env: Client_types.environment, ~setEnv) => {
  Js.log2("ENV", env);
  <div className="tile is-vertical box">
    <Components.NamedInput
      label="break rate"
      value={env.break_rate}
      setValue={new_value => setEnv(_ => {...env, break_rate: new_value})}
    />
    <Components.NamedInput
      label="grab rate"
      value={env.grab_rate}
      setValue={new_value => setEnv(_ => {...env, grab_rate: new_value})}
    />
    <Components.NamedInput
      label="transition rate"
      value={env.transition_rate}
      setValue={new_value =>
        setEnv(_ => {...env, transition_rate: new_value})
      }
    />
    <Components.NamedInput
      label="collision rate"
      value={env.collision_rate}
      setValue={new_value => setEnv(_ => {...env, collision_rate: new_value})}
    />
  </div>;
};
