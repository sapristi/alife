open Utils;
open Client_types;
open Components;

module Style = {
  let reactant = Css.(style([maxWidth(vw(80.))]));
  let reactant_info = Css.(style([marginRight(px(14))]));
};
module Amd = {
  [@react.component]
  let make = (~amd) => {
    let pnet_id = amd.pnet_id;
    <HFlex>
      <span style=Style.reactant_info>
        {j|Active(id:$(pnet_id)) |j}->React.string
      </span>
      <Molecule mol={amd.mol} />
    </HFlex>;
  };
};
module Inert = {
  [@react.component]
  let make = (~inert_mol) => {
    let qtt = inert_mol.qtt;
    <HFlex>
      <span style=Style.reactant_info>
        {j|Inert(qtt: $(qtt)) |j}->React.string
      </span>
      <Molecule mol={inert_mol.mol} />
    </HFlex>;
  };
};

module Reactant = {
  [@react.component]
  let make = (~reactant: Reactions.reactant) => {
    switch (reactant) {
    | ImolSet(inert_mol) => <Inert inert_mol />
    | Amol(amd) => <Amd amd />
    };
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
  let make_key = elem =>
    switch (Js.Json.stringifyAny(elem)) {
    | Some(s) => s
    | None => Js.Math.random()->Js.Float.toString
    };
  let make = (props: {. "reactions": array(reac_type)}) => {
    let (opened, setOpen) = React.useState(() => false);
    let icon = opened ? <Icons.ChevronUp /> : <Icons.ChevronDown />;
    <React.Fragment>
      <tr>
        <td colSpan=2>
          <Button onClick={_ => setOpen(v => !v)}>
            <h3 className="subtitle">
              <HFlex style=Css.[alignContent(center)]>
                icon
                Reacs.name->React.string
              </HFlex>
            </h3>
          </Button>
        </td>
      </tr>
      {if (opened) {
         Array.map(
           reac => <Reacs key={make_key()} reaction=reac />,
           props##reactions,
         )
         ->ReasonReact.array;
       } else {
         React.null;
       }}
    </React.Fragment>;
  };
};
module TReacs: REACS with type reac_type = Reactions.transition = {
  [@decco.decode]
  type reac_type = Reactions.transition;
  let name = "Transitions";
  [@react.component]
  let make = (~reaction: Reactions.transition) => {
    <tr>
      <td> reaction.rate->React.string </td>
      <td style=Style.reactant> <Amd amd={reaction.amd} /> </td>
    </tr>;
  };
};
module TReacsC = MakeReacTree(TReacs);

module GReacs: REACS with type reac_type = Reactions.grab = {
  [@decco.decode]
  type reac_type = Reactions.grab;
  let name = "Grabs";
  [@react.component]
  let make = (~reaction: Reactions.grab) => {
    <React.Fragment>
      <tr>
        <td rowSpan=2> reaction.rate->React.string </td>
        <td style=Style.reactant> <Amd amd={reaction.graber_data} /> </td>
      </tr>
      <tr>
        <td style=Style.reactant>
          <Reactant reactant={reaction.grabed_data} />
        </td>
      </tr>
    </React.Fragment>;
  };
};
module GReacsC = MakeReacTree(GReacs);

module BReacs: REACS with type reac_type = Reactions.break = {
  [@decco.decode]
  type reac_type = Reactions.break;
  let name = "Breaks";
  [@react.component]
  let make = (~reaction: Reactions.break) => {
    <tr>
      <td> reaction.rate->React.string </td>
      <td style=Style.reactant> <Reactant reactant={reaction.reactant} /> </td>
    </tr>;
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

  let reactions_counter = "#" ++ state.reac_counter->string_of_int;
  <Panel collapsable=true>
    (
      <HFlex>
        "Reactions"->React.string
        reactions_counter->React.string
      </HFlex>,
      <table className="table">
        <thead>
          <tr>
            <th> "Rate"->React.string </th>
            <th colSpan=2> "Reactants"->React.string </th>
          </tr>
        </thead>
        <tbody>
          <TReacsC reactions={state.transitions.reactions} />
          <GReacsC reactions={state.grabs.reactions} />
          <BReacsC reactions={state.breaks.reactions} />
        </tbody>
      </table>,
    )
  </Panel>;
};
