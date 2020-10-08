open Components;
open Utils;

module EnvControls = Sandbox__generic_controls__env_controls;



module NoData = {
  [@decco]
  type post = {
    name: string,
    description: string,
  };

  let make_post_request = (db_name, data: post) => {
    let data_json = post_encode(data);
    Yaac.request_unit(Fetch.Post, "/sandbox/db/" ++ db_name, ~payload=data_json, ());
  };

  [@react.component]
  let make = (~setShow, ~db_name) => {
    let (description, setDescription) = React.useState(() => "");
    let (name, setName) = React.useState(() => "");
    let post = React.useMemo1(((), data) => make_post_request(db_name, data), [|db_name|]);
    let handleResponse =
      React.useCallback1(
        () =>
          setShow(prev =>
            switch (prev) {
            | Some(callback) =>
              callback();
              None;
            | None => None
            }
          ),
        [|setShow|],
      );

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
      <Button
        onClick={_ => {
          post({name, description})
          ->Promise.getOk( handleResponse )
        }}>
        "Post"->React.string
      </Button>
    </div>;
  };
};

module Env = {
  [@decco]
  type post = {
    name: string,
    description: string,
    data: Client_types.environment,
  };

  let post = (data: post) =>
    {
      let data_json = post_encode(data);
      Yaac.request_unit(Fetch.Post, "/sandbox/db/environment", ~payload=data_json, ());
    };

  [@react.component]
  let make = (~env, ~seed, ~setShow) => {
    let (description, setDescription) = React.useState(() => "");
    let (name, setName) = React.useState(() => "");
    let (innerEnv, setInnerEnv) = React.useState(() => env);
    let handleResponse =
      React.useCallback1(
      () =>
        setShow(prev =>
                switch (prev) {
                | Some(callback) =>
                  callback();
                  None;
                | None => None
                }
      ),
      [|setShow|],
    );

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
      <EnvControls env=innerEnv setEnv=setInnerEnv />
      <Button
        onClick={_ => {
          post({name, description, data: innerEnv})->Promise.getOk(handleResponse);
        }}>
        "Post"->React.string
      </Button>
    </div>;
  };
};
