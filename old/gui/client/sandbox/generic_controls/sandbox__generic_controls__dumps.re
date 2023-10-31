open Components;
open Utils;

module Forms = Sandbox__generic_controls__forms;
module MakeTable = Sandbox__generic_controls__table.MakeTable;

module DumpForm = {
  [@decco]
  type post = {
    name: string,
    description: string,
  };

  let post = (data: post) =>
    {
      let data_json = post_encode(data);
      Yaac.request_unit(Fetch.Post, "/sandbox/db/dump", ~payload=data_json, ());
    }
    ->ignore;

  [@react.component]
  let make = (~setShow) => {
    let (description, setDescription) = React.useState(() => "");
    let (name, setName) = React.useState(() => "");
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
          post({name, description});
          setShow(prev =>
            switch (prev) {
            | Some(callback) =>
              callback();
              None;
            | None => None
            }
          );
        }}>
        "Post"->React.string
      </Button>
    </div>;
  };
};

let download_dumps = _ =>
  Yaac.request(Fetch.Get, "/sandbox/dump/dump", ~json_decode=x => Ok(x), ())
  ->Promise.getOk(res => {
      Js.log2("dump", res);
      let data = Js.Json.stringify(res);
      let blob = makeBlob([|data|], {"type": "text/plain"});
      Js.log2("blob", blob);
      saveAs(blob, "dumps_dump.json");
    });

module DumpsTable =
  MakeTable({
    let db_name = "dump";
  });

[@react.component]
let make = (~update) => {
  let (showDialog, setShowDialog) = React.useState(() => None);
  let globalActions =
    React.useMemo1(
      () =>
        [|
          (
            onClick => <ButtonIcon key="dumps" onClick> <Icons.Save /> </ButtonIcon>,
            updateChange => setShowDialog(_ => Some(updateChange)),
          ),
        |],
      [|setShowDialog|],
    );

  <div className="box">
    <h5 className="title nice-title is-5"> "Dumped states"->React.string </h5>
    <HFlex style=Css.[marginBottom(px(0))]>
      <Modal isOpen={showDialog != None} onRequestClose={_ => setShowDialog(_ => None)}>
        <Forms.NoData db_name="dump" setShow=setShowDialog />
      </Modal>
      <DumpsTable update globalActions />
      <div className="buttons has-addons">
        <Button onClick=download_dumps> "Dump signatures"->React.string </Button>
        <Button> "Load signatures dump"->React.string </Button>
      </div>
    </HFlex>
  </div>;
};
