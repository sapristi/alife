open Components;
open Utils;

module Forms = Sandbox__generic_controls__forms;
module MakeTable = Sandbox__generic_controls__table.MakeTable;

module SignaturesTable = MakeTable({let db_name = "bactsig"});
module EnvsTable = MakeTable({let db_name = "environment"});


[@react.component]
let make = (~update, ~env, ~seed) => {
  let (showEnvDialog, setShowEnvDialog) = React.useState(() => None);
  let (showSigDialog, setShowSigDialog) = React.useState(() => None);

  let (sigGlobalActions, envGlobalActions) =
    React.useMemo2(
    () => {
      ([|("Save current", updateChange => setShowSigDialog(_ => Some(updateChange)))|],
      [|("Save current", updateChange => setShowEnvDialog(_ => Some(updateChange)))|])
    }
      ,
    (setShowEnvDialog, setShowSigDialog),
  );


  <div className="box">
    <h5 className="title nice-title is-5"> "Predefined states"->React.string </h5>
    <HFlex style=Css.[marginBottom(px(0))]>
      <Modal isOpen={showEnvDialog != None} onRequestClose={_ => setShowEnvDialog(_ => None)}>
        <Forms.Env env seed setShow=setShowSigDialog />
      </Modal>
      <Modal isOpen={showSigDialog != None} onRequestClose={_ => setShowSigDialog(_ => None)}>
        <Forms.NoData db_name="bactsig" setShow=setShowEnvDialog />
      </Modal>

      <SignaturesTable update globalActions=sigGlobalActions/>
      <EnvsTable update globalActions=envGlobalActions/>
    </HFlex>
  </div>;
};
