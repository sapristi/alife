open Utils;
open Acid_types;
open Components;

module InputArcComp = {
  [@react.component]
  let make = (~id, ~iarc_type, ~dispatch) => {
    switch (iarc_type) {
    | Regular_iarc => "Regular"->React.string
    | Split_iarc => "Split"->React.string
    | Filter_iarc(filter) => <> "Filter"->React.string <Input.Text value=filter setValue={_ => ()} /> </>
    | Filter_empty_iarc => "Filter empty"->React.string
    };
  };
};

module OutputArcComp = {
  [@react.component]
  let make = (~id, ~oarc_type, ~dispatch) => {
    switch (oarc_type) {
    | Regular_oarc => "Regular"->React.string
    | Merge_oarc => "Merge"->React.string
    | Move_oarc(b) => "Move"->React.string
    };
  };
};

module ExtensionComp = {
  [@react.component]
  let make = (~id, ~extension_type, ~dispatch) => {
    switch (extension_type) {
    | Grab_ext(pattern) => <> "Grab"->React.string <Input.Text value=pattern setValue={_ => ()} /> </>
    | Release_ext => "Release"->React.string
    | Init_with_token_ext => "Init with token"->React.string
    };
  };
};

[@react.component]
let make = (~id, ~acid, ~dispatch) => {
  let (currentAcid, setCurrentAcid) = React.useState(() => acid);

  switch (acid) {
  | Place => "Place"->React.string
  | InputArc(tid, iarc_type) =>
    <>
      "InputArc"->React.string
      <Input.Text value=tid setValue={_ => ()} />
      <InputArcComp id iarc_type dispatch />
    </>
  | OutputArc(tid, oarc_type) =>
    <>
      "OutputArc"->React.string
      <Input.Text value=tid setValue={_ => ()} />
      <OutputArcComp id oarc_type dispatch />
    </>
  | Extension(extension_type) => <> "Extension"->React.string <ExtensionComp id extension_type dispatch /> </>
  };
};
