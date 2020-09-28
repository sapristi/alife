open Components;
open Utils;

module SignatureForm = Sandbox__generic_controls__signature_form;

module SignaturesTable = {
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
          Yaac.request_unit(Fetch.Post, "/sandbox/signature/" ++ name ++ "/load", ())
          ->Promise.getOk(update),
        [|update|],
      );

    let columns = makeColumns(commitLoad);

    React.useEffect0(() => {
      Yaac.request(Fetch.Get, "/sandbox/signature", ~json_decode=data_decode, ())
      ->Promise.getOk(data => {setValues(_ => data)});
      None;
    });

    <div style=Css.(style([maxHeight(px(300)), overflow(auto)]))>
      <Table columns data=values getRowKey />
    </div>;
  };
};

let download_dumps = _ => Yaac.request(
  Fetch.Get, "/sandbox/signature/dump",
  ~json_decode={x => Ok(x)},
  ()
)->Promise.getOk( res => {

  Js.log2("dump", res);
  let data = Js.Json.stringify(res);
  let blob = makeBlob([|data|], {"type": "text/plain"});
  Js.log2("blob", blob);
  saveAs(blob, "signatures_dump.json")
});


[@react.component]
let make = (~update, ~env, ~seed) => {
  let (showDialog, setShowDialog) = React.useState(() => false);

  <div className="box">
  <h5 className="title nice-title is-5"> "Predefined states"->React.string </h5>
  <HFlex style=Css.[marginBottom(px(0))]>
    <Modal isOpen=showDialog onRequestClose={_ => setShowDialog(_ => false)}>
      <SignatureForm env seed />
    </Modal>
    <SignaturesTable update />
    <div className="buttons has-addons">
      <Button onClick={_ => setShowDialog(_ => true)}> "Save current"->React.string </Button>
      <Button onClick=download_dumps>"Dump signatures"->React.string</Button>
      <Button >"Load signatures dump"->React.string</Button>
    </div>
  </HFlex>

  </div>
  ;
};
