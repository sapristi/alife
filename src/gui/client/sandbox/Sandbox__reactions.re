open Utils;
open Client_types;
open Components;

module Amd = {
  [@react.component]
  let make = (~amd) => {
    <div> {j|Active(id: {amd.pnet_id}) {amd.mol}|j}->React.string </div>;
  };
};
module Inert = {
  [@react.component]
  let make = (~inert_mol) => {
    <div> {j|Inert(qtt: {inert_mol.qtt}) {amd.mol}|j}->React.string </div>;
  };
};

module type REACS = {
  [@decco.decode]
  type reac_type;
  let name: string;
  let makeProps:
    (~reaction: reac_type, ~key: string=?, unit) => {. "reaction": reac_type};

  let make: {. "reaction": reac_type} => React.element;
};

module type REAC_TREE = {
  type reac_type;
  let makeProps:
    (~reactions: array(reac_type), ~key: string=?, unit) =>
    {. "reactions": array(reac_type)};

  let make: {. "reactions": array(reac_type)} => React.element;

  type reacs_res = {
    reactions: array(reac_type),
    total: string,
  };

  let default_res: reacs_res;
  let reacs_res_decode:
    Js.Json.t => Belt.Result.t(reacs_res, Decco.decodeError);
};

module MakeReacTree =
       (Reacs: REACS)
       : (REAC_TREE with type reac_type = Reacs.reac_type) => {
  type reac_type = Reacs.reac_type;

  [@decco.decode]
  type reacs_res = {
    reactions: array(Reacs.reac_type),
    total: string,
  };
  let default_res = {reactions: [||], total: "0"};

  [@bs.obj]
  external makeProps:
    (~reactions: array(reac_type), ~key: string=?, unit) =>
    {. "reactions": array(reac_type)};
  let make = (props: {. "reactions": array(reac_type)}) => {
    <div className="content">
      Reacs.name->React.string
      <ul>
        {Array.map(
           reac => <li> <Reacs reaction=reac /> </li>,
           props##reactions,
         )
         ->ReasonReact.array}
      </ul>
    </div>;
  };
};
module TReacs: REACS with type reac_type = Reactions.transition = {
  [@decco.decode]
  type reac_type = Reactions.transition;
  let name = "Transitions";
  [@react.component]
  let make = (~reaction: Reactions.transition) => {
    let rate = reaction.rate;
    <HFlex>
      {j|Rate: $(rate)|j}->React.string
      <Amd amd={reaction.amd} />
    </HFlex>;
  };
};
module TReacsC = MakeReacTree(TReacs);

module GReacs: REACS with type reac_type = Reactions.grab = {
  [@decco.decode]
  type reac_type = Reactions.grab;
  let name = "Grab";
  [@react.component]
  let make = (~reaction: Reactions.grab) => {
    <HFlex> reaction.rate->React.string </HFlex>;
  };
};
module GReacsC = MakeReacTree(GReacs);

module BReacs: REACS with type reac_type = Reactions.break = {
  [@decco.decode]
  type reac_type = Reactions.break;
  let name = "Breaks";
  [@react.component]
  let make = (~reaction: Reactions.break) => {
    <HFlex> reaction.rate->React.string </HFlex>;
  };
};
module BReacsC = MakeReacTree(BReacs);

[@decco.decode]
type reactions_state = {
  transitions: TReacsC.reacs_res,
  grabs: GReacsC.reacs_res,
  breaks: BReacsC.reacs_res,
  reac_counter: int,
  env: environment,
};

let default_state = {
  transitions: TReacsC.default_res,
  grabs: GReacsC.default_res,
  breaks: BReacsC.default_res,
  reac_counter: 0,
  env: default_env,
};

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

  <Panel collapsable=true>
    (
      "Reactions"->React.string,
      <React.Fragment>
        <TReacsC reactions={state.transitions.reactions} />
        <GReacsC reactions={state.grabs.reactions} />
        <BReacsC reactions={state.breaks.reactions} />
      </React.Fragment>,
    )
  </Panel>;
};
