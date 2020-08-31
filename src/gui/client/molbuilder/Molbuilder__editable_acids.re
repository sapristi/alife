open Utils;
open Acid_types;
open Components;

let inputStyle =
  Css.[
    padding2(~v=px(0), ~h=px(3)),
    height(em(1.5)),
    fontFamily(`monospace),
  ];

module InputArcComp = {
  [@react.component]
  let make = (~id, ~iarc_type, ~update) => {
    switch (iarc_type) {
    | Regular_iarc => "Regular"->React.string
    | Split_iarc => "Split"->React.string
    | Filter_iarc(filter) =>
      <HFlex style=Css.[alignItems(center)]>
        "Filter"->React.string
        <Input.TextInline
          value=filter
          setValue={new_filter => update(Filter_iarc(new_filter))}
          style=inputStyle
        />
      </HFlex>
    | Filter_empty_iarc => "Filter empty"->React.string
    };
  };
};

module OutputArcComp = {
  [@react.component]
  let make = (~id, ~oarc_type, ~update) => {
    switch (oarc_type) {
    | Regular_oarc => "Regular"->React.string
    | Merge_oarc => "Merge"->React.string
    | Move_oarc(b) =>
      <HFlex style=Css.[alignItems(center)]>
        "Move"->React.string
        <Input.Select
          options=[("true", "forward"), ("false", "backward")]
          initValue={string_of_bool(b)}
          setValue={new_b => update(Move_oarc(bool_of_string(new_b())))}
          modifiers=["is-small"]
        />
      </HFlex>
    };
  };
};

module ExtensionComp = {
  [@react.component]
  let make = (~id, ~extension_type, ~update) => {
    switch (extension_type) {
    | Grab_ext(pattern) =>
      <HFlex style=Css.[alignItems(center)]>
        "Grab"->React.string
        <Input.TextInline
          value=pattern
          setValue={new_pattern => update(Grab_ext(new_pattern))}
          style=inputStyle
        />
      </HFlex>
    | Release_ext => "Release"->React.string
    | Init_with_token_ext => "Init with token"->React.string
    };
  };
};

[@react.component]
let make = (~id, ~acid, ~update, ~delete) => {
  let inner =
    switch (acid) {
    | Place => "Place"->React.string
    | InputArc(tid, iarc_type) =>
      <>
        <InputArcComp
          id
          iarc_type
          update={new_iarc_type => update(InputArc(tid, new_iarc_type))}
        />
        <HFlex
          style=Css.[
            marginLeft(px(5)),
            justifyContent(spaceBetween),
            alignItems(center),
          ]>
          "InputArc"->React.string
          <Input.TextInline
            value=tid
            setValue={new_tid => update(InputArc(new_tid, iarc_type))}
            style=inputStyle
          />
        </HFlex>
      </>
    | OutputArc(tid, oarc_type) =>
      <>
        <OutputArcComp
          id
          oarc_type
          update={new_oarc_type => update(OutputArc(tid, new_oarc_type))}
        />
        <HFlex
          style=Css.[
            marginLeft(px(5)),
            justifyContent(spaceBetween),
            alignItems(center),
          ]>
          "OutputArc"->React.string
          <Input.TextInline
            value=tid
            setValue={new_tid => update(OutputArc(new_tid, oarc_type))}
            style=inputStyle
          />
        </HFlex>
      </>
    | Extension(extension_type) =>
      <>
        <ExtensionComp
          id
          extension_type
          update={new_ext => Extension(new_ext)}
        />
        <div> "Extension"->React.string </div>
      </>
    };
  let marginSize =
    switch (acid) {
    | Place => 0
    | _ => 15
    };

  <div style=Css.(style([borderBottom(px(1), solid, black)]))>
    <HFlex
      style=Css.[
        justifyContent(spaceBetween),
        alignItems(center),
        marginLeft(px(marginSize)),
      ]>
      <HFlex
        style=Css.[
          justifyContent(spaceBetween),
          alignItems(center),
          width(pct(100.)),
          marginRight(px(15)),
        ]>
        inner
      </HFlex>
      <button onClick=delete className="button is-small">
        <Icons.DeleteIcon />
      </button>
    </HFlex>
  </div>;
};
