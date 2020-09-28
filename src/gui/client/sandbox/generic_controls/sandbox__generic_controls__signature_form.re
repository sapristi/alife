open Components;
open Utils;

module EnvControls = Sandbox__generic_controls__env_controls;

[@decco]
type post = {
  name: string,
  description: string,
  env: Client_types.environment,
  seed: int,
};

let post = (data: post) =>
  {
    let data_json = post_encode(data);
    Yaac.request_unit(Fetch.Post, "/sandbox/signature", ~payload=data_json, ());
  }
  ->ignore;

[@react.component]
let make = (~env, ~seed, ~setShow) => {
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
    <Button
      onClick={_ => {
        post({name, description, env: innerEnv, seed: innerSeed});
        setShow(_ => false);
      }}>
      "Post"->React.string
    </Button>
  </div>;
};
