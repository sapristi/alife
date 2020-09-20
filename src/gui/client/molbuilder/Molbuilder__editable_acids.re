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
  let make = (~iarc_type, ~update) => {
    switch (iarc_type) {
    | Regular_iarc => "Regular"->React.string
    | Split_iarc => "Split"->React.string
    | Filter_iarc(filter) =>
      <HFlex style=Css.[alignItems(center)]>
        "Filter"->React.string
        <Input.TextInline
          value=filter
          setValue={new_filter => update(Filter_iarc(new_filter))}
          styles=inputStyle
        />
      </HFlex>
    | Filter_empty_iarc => "Filter empty"->React.string
    };
  };
};

module OutputArcComp = {
  [@react.component]
  let make = (~oarc_type, ~update) => {
    switch (oarc_type) {
    | Regular_oarc => "Regular"->React.string
    | Merge_oarc => "Merge"->React.string
    | Move_oarc(b) =>
      <HFlex style=Css.[alignItems(center)]>
        "Move"->React.string
        <Input.Select
          options=[|("true", "forward"), ("false", "backward")|]
          value={string_of_bool(b)}
          onChange={new_b => update(Move_oarc(bool_of_string(new_b)))}
          modifiers=["is-small"]
        />
      </HFlex>
    };
  };
};

module ExtensionComp = {
  [@react.component]
  let make = (~extension_type, ~update) => {
    switch (extension_type) {
    | Grab_ext(pattern) =>
      <HFlex style=Css.[alignItems(center)]>
        "Grab"->React.string
        <Input.TextInline
          value=pattern
          setValue={new_pattern => update(Grab_ext(new_pattern))}
          styles=inputStyle
        />
      </HFlex>
    | Release_ext => "Release"->React.string
    | Init_with_token_ext => "Init with token"->React.string
    };
  };
};

[@react.component]
let make = (~acid, ~update, ~delete) => {
  let inner =
    switch (acid) {
    | Place => "Place"->React.string
    | InputArc(tid, iarc_type) =>
      <>
        <InputArcComp
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
            styles=inputStyle
          />
        </HFlex>
      </>
    | OutputArc(tid, oarc_type) =>
      <>
        <OutputArcComp
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
            styles=inputStyle
          />
        </HFlex>
      </>
    | Extension(extension_type) =>
      <>
        <ExtensionComp
          extension_type
          update={new_ext => update(Extension(new_ext))}
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
        <span className="icon"> <Icons.Delete /> </span>
      </button>
    </HFlex>
  </div>;
};
