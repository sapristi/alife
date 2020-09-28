open Components;
open Utils;

module SignatureForm = Sandbox__generic_controls__signature_form;

module DumpForm = {
  [@decco]
  type post = {
    name: string,
    description: string,
  };

  let post = (data: post) =>
    {
      let data_json = post_encode(data);
      Yaac.request_unit(Fetch.Post, "/sandbox/dump", ~payload=data_json, ());
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
          setShow(_ => false);
        }}>
        "Post"->React.string
      </Button>
    </div>;
  };
};

module DumpsTable = {
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
          Yaac.request_unit(Fetch.Post, "/sandbox/dump/" ++ name ++ "/load", ())
          ->Promise.getOk(update),
        [|update|],
      );

    let columns = makeColumns(commitLoad);

    React.useEffect0(() => {
      Yaac.request(Fetch.Get, "/sandbox/dump", ~json_decode=data_decode, ())
      ->Promise.getOk(data => {setValues(_ => data)});
      None;
    });

    <div style=Css.(style([maxHeight(px(300)), overflow(auto)]))>
      <Table columns data=values getRowKey />
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

[@react.component]
let make = (~update) => {
  let (showDialog, setShowDialog) = React.useState(() => false);

  <div className="box">
    <h5 className="title nice-title is-5"> "Dumped states"->React.string </h5>
    <HFlex style=Css.[marginBottom(px(0))]>
      <Modal isOpen=showDialog onRequestClose={_ => setShowDialog(_ => false)}>
        <DumpForm setShow=setShowDialog />
      </Modal>
      <DumpsTable update />
      <div className="buttons has-addons">
        <Button onClick={_ => setShowDialog(_ => true)}> "Save current"->React.string </Button>
        <Button onClick=download_dumps> "Dump signatures"->React.string </Button>
        <Button> "Load signatures dump"->React.string </Button>
      </div>
    </HFlex>
  </div>;
};
