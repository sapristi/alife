open Utils;
open Client_types;
[@decco]
type amd = {
  mol: string,
  pnet_id: int,
};

[@decco]
type imolset = {
  mol: string,
  qtt: int,
  ambient: bool,
};

[@decco]
type reactant =
  | ImolSet(imolset)
  | Amol(amd);

[@decco]
type transition = {
  rate: string,
  amd,
};

[@decco]
type grab = {
  rate: string,
  graber_data: amd,
  grabed_data: reactant,
};

[@decco]
type break = {
  rate: string,
  reactant,
};

[@decco]
type reactions_state = {
  transitions: list(transition),
  grabs: list(grab),
  breaks: list(break),
  reac_counter: int,
  env: environment,
};

let default_state = {
  transitions: [],
  grabs: [],
  breaks: [],
  reac_counter: 0,
  env: default_env,
};

module type REACS = {
  type reac_type;
  let name: string;
};

module type REAC_TREE = {
  type reac_type;
  type props = {reactions: list(reac_type)};
  let make: props => React.element;
};

let reac_to_string = reac =>
  switch (Js.Json.stringifyAny(reac)) {
  | None => ""
  | Some(s) => s
  };

module MakeReacTree =
       (Reacs: REACS)
       : (REAC_TREE with type reac_type = Reacs.reac_type) => {
  type reac_type = Reacs.reac_type;
  type props = {reactions: list(reac_type)};
  let make = ({reactions}: props) => {
    <div>
      Reacs.name->React.string
      <ul>
        {List.map(
           reac => <li> {reac->reac_to_string->React.string} </li>,
           reactions,
         )
         ->Generics.react_list}
      </ul>
    </div>;
  };
};
module TReacs: REACS with type reac_type = transition = {
  type reac_type = transition;
  let name = "transitions";
};
module TReacsC = MakeReacTree(TReacs);

module GReacs: REACS with type reac_type = grab = {
  type reac_type = grab;
  let name = "grab";
};
module GReacsC = MakeReacTree(GReacs);

module BReacs: REACS with type reac_type = break = {
  type reac_type = break;
  let name = "breaks";
};
module BReacsC = MakeReacTree(BReacs);

[@react.component]
let make = (~updateSwitch) => {
  let (state: reactions_state, setState) =
    React.useState(() => default_state);
  React.useEffect1(
    () => {
      Js.log("Updating reactions");
      Yaac.request(
        Fetch.Get,
        "/sandbox/reaction",
        ~json_decode=reactions_state_decode,
        (),
      )
      ->Promise.getOk(res => {
          Js.log2("Got reactions", res);
          setState(_ => res);
        });

      None;
    },
    [|updateSwitch|],
  );

  <React.Fragment>
    {TReacsC.make({reactions: state.transitions})}
    {GReacsC.make({reactions: state.grabs})}
    {BReacsC.make({reactions: state.breaks})}
  </React.Fragment>;
};
