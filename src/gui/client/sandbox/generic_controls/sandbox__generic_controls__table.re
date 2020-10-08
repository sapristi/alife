open Components;
open Utils;

module MakeTable = (Endpoint: {let db_name: string;}) => {
  let path_prefix = "/sandbox/db/" ++ Endpoint.db_name;

  [@decco]
  type data_item = {
    name: string,
    description: string,
    time: string,
  };
  [@decco]
  type data = array(data_item);

  let makeColumns =
      (loadAction, deleteAction, downloadAllAction, globalActions, updateChange)
      : array(Table.column(data_item)) => [|
    {
      style: [],
      header: () => "Name"->React.string,
      makeCell: row =>
        <div className="tooltip">
          <div className="tooltiptext"> row.description->React.string </div>
          row.name->React.string
        </div>,

      key: "name",
    },
    {
      style: [],
      header: () =>
        <HFlex style=Css.[alignItems(center)]>
          "Actions"->React.string
          <Button onClick={_ => downloadAllAction()}> "Download all"->React.string </Button>
          {Array.map(
             ((name, action)) =>
               <Button onClick={_ => action(updateChange)} key=name>
                 name->React.string
               </Button>,
             globalActions,
           )
           ->React.array}
        </HFlex>,
      makeCell: row =>
        <HFlex>
          <Button onClick={_ => loadAction(row.name)}> "Load"->React.string </Button>
          <Button onClick={_ => deleteAction(row.name)}> "Delete"->React.string </Button>
        </HFlex>,

      key: "action",
    },
  |];

  let getRowKey = row => row.name;

  [@react.component]
  let make = (~update, ~globalActions) => {
    let (values, setValues) = React.useState(_ => [||]);
    let (change, updateChange) = React.useReducer((s, ()) => !s, true);

    let columns =
      React.useMemo3(
        () => {
          let loadAction = name =>
            Yaac.request_unit(Fetch.Post, path_prefix ++ "/" ++ name ++ "/load", ())
            ->Promise.getOk(() => {
                update();
                updateChange();
              });

          let deleteAction = name =>
            Yaac.request_unit(Fetch.Delete, path_prefix ++ "/" ++ name, ())
            ->Promise.getOk(() => {
                update();
                updateChange();
              });

          let downloadAllAction = () =>
            Yaac.request(Fetch.Get, path_prefix ++ "/dump", ~json_decode=x => Ok(x), ())
            ->Promise.getOk(res => {
                let data = Js.Json.stringify(res);
                let blob = makeBlob([|data|], {"type": "text/plain"});
                saveAs(blob, Endpoint.db_name ++ "_dump.json");
              });

          makeColumns(loadAction, deleteAction, downloadAllAction, globalActions, updateChange);
        },
        (update, updateChange, globalActions),
      );

    React.useEffect1(
      () => {
        Yaac.request(Fetch.Get, path_prefix, ~json_decode=data_decode, ())
        ->Promise.getOk(data => {setValues(_ => data)});
        None;
      },
      [|change|],
    );

    <div style=Css.(style([maxHeight(px(300)), overflow(auto)]))>
      <Table columns data=values getRowKey />
    </div>;
  };
};