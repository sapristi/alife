open Utils;
open Components;
[@react.component]
let make = (~env: Client_types.environment, ~setEnv) => {
  <div className="tile is-vertical box">
    <Input.NamedInput label="break rate">
      <Input.Text
        value={env.break_rate}
        onChange={new_value => setEnv(_ => {...env, break_rate: new_value})}
      />
    </Input.NamedInput>
    <Input.NamedInput label="grab rate">
      <Input.Text
        value={env.grab_rate}
        onChange={new_value => setEnv(_ => {...env, grab_rate: new_value})}
      />
    </Input.NamedInput>
    <Input.NamedInput label="transition rate">
      <Input.Text
        value={env.transition_rate}
        onChange={new_value => setEnv(_ => {...env, transition_rate: new_value})}
      />
    </Input.NamedInput>
    <Input.NamedInput label="collision rate">
      <Input.Text
        value={env.collision_rate}
        onChange={new_value => setEnv(_ => {...env, collision_rate: new_value})}
      />
    </Input.NamedInput>
  </div>;
};
