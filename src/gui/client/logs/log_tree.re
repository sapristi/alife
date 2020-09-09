open Components;

let log_levels = [
  "Debug",
  "Trace",
  "Info",
  "Warning",
  "Error",
  "Flash",
  "NoLevel",
];

[@decco.decode]
type log_node = {
  name: string,
  level: string,
  children: array(log_node),
};

[@decco.encode]
type post_request = {
  level: string,
  logger: string,
};

let commitLevel = (logger, level) =>
  Utils__yaac.request_unit(
    Fetch.Post,
    "/logs/logger",
    ~payload=post_request_encode({logger, level}),
    (),
  )
  ->ignore;

module LogItem = {
  let log_level_to_option = level => (level, level);

  [@react.component]
  let make = (~name, ~level) => {
    let (newLevel, setNewLevel) = React.useState(() => level);
    <HFlex>
      name->React.string
      <Components__input.Select
        options={List.map(log_level_to_option, log_levels)}
        initValue=level
        setValue=setNewLevel
        modifiers=["is-small"]
      />
      <Components__button.Button onClick={_ => commitLevel(name, newLevel)}>
        "Commit"->React.string
      </Components__button.Button>
    </HFlex>;
  };
};

module type LOGTREE = {
  let makeProps:
    (~log_node: 'log_node, ~key: string=?, unit) => {. "log_node": 'log_node};
  let make: {. "log_node": log_node} => React.element;
};

module rec LogTree: LOGTREE = {
  [@react.component]
  let make = (~log_node) => {
    <React.Fragment>
      <LogItem name={log_node.name} level={log_node.level} />
      <ul>
        {Array.map(
           node => <li key={node.name}> <LogTree log_node=node /> </li>,
           log_node.children,
         )
         ->React.array}
      </ul>
    </React.Fragment>;
  };
};

[@react.component]
let make = () => {
  let (logTree, setLogTree) = React.useState(() => None);
  React.useEffect0(() => {
    Utils__yaac.request(
      Fetch.Get,
      "/logs/tree",
      ~json_decode=log_node_decode,
      (),
    )
    ->Promise.getOk(tree => setLogTree(_ => Some(tree)));
    None;
  });
  Js.log2("Got log tree", logTree);
  switch (logTree) {
  | None => React.null
  | Some(log_node) => <div className="content"> <LogTree log_node /> </div>
  };
};
