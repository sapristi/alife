open Components;
module EnvControls = Sandbox__generic_controls__env_controls;

[@react.component]
let make = (~env, ~seed) => {
  let (description, setDescription) = React.useState(() => "");
  let (name, setName) = React.useState(() => "");
  let (innerEnv, setInnerEnv) = React.useState(() => env);
  let (innerSeed, setInnerSeed) = React.useState(() => seed);
  <div>
    <Input.NamedInput label="Name">
      <Input.Text value=name onChange={new_name => setName(_ => new_name)} />
    </Input.NamedInput>
    <Input.NamedInput label="Description">
      <Input.Text
        value=description
        onChange={new_description => setDescription(_ => new_description)}
        multiline=true
      />
    </Input.NamedInput>
    <Input.NamedInput label="Random seed">
      <Input.Text
        value={innerSeed->string_of_int}
        onChange={new_seed => setInnerSeed(_ => int_of_string(new_seed))}
      />
    </Input.NamedInput>
    <EnvControls env=innerEnv setEnv=setInnerEnv />
  </div>;
};
