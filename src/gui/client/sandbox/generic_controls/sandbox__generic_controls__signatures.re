open Components;
open Utils;

module SignatureForm = Sandbox__generic_controls__signature_form;
module MakeTable = Sandbox__generic_controls__table.MakeTable;

module SignaturesTable = MakeTable({let db_name = "bactsig"});
module EnvsTable = MakeTable({let db_name = "environment"});

let download_dumps = _ =>
  Yaac.request(Fetch.Get, "/sandbox/db/bactsig/dump", ~json_decode=x => Ok(x), ())
  ->Promise.getOk(res => {
      Js.log2("dump", res);
      let data = Js.Json.stringify(res);
      let blob = makeBlob([|data|], {"type": "text/plain"});
      Js.log2("blob", blob);
      saveAs(blob, "bact_sigs_dump.json");
    });

[@react.component]
let make = (~update, ~env, ~seed) => {
  let (showDialog, setShowDialog) = React.useState(() => false);

  <div className="box">
    <h5 className="title nice-title is-5"> "Predefined states"->React.string </h5>
    <HFlex style=Css.[marginBottom(px(0))]>
      <Modal isOpen=showDialog onRequestClose={_ => setShowDialog(_ => false)}>
        <SignatureForm env seed setShow=setShowDialog />
      </Modal>
      <SignaturesTable update />
      <EnvsTable update />
    </HFlex>
  </div>;
};
