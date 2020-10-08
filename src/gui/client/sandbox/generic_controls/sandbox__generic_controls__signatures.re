open Components;
open Utils;

module Forms = Sandbox__generic_controls__forms;
module MakeTable = Sandbox__generic_controls__table.MakeTable;

module SignaturesTable =
  MakeTable({
    let db_name = "bactsig";
  });
module EnvsTable =
  MakeTable({
    let db_name = "environment";
  });

[@react.component]
let make = (~update, ~env, ~seed) => {
  let (showEnvDialog, setShowEnvDialog) = React.useState(() => None);
  let (showSigDialog, setShowSigDialog) = React.useState(() => None);

  let (sigGlobalActions, envGlobalActions) =
    React.useMemo2(
      () => {
        (
          [|
            (
              onClick => <ButtonIcon key="sig" onClick> <Icons.Save /> </ButtonIcon>,
              updateChange => setShowSigDialog(_ => Some(updateChange)),
            ),
          |],
          [|
            (
            onClick => <ButtonIcon key="env"  onClick> <Icons.Save /> </ButtonIcon>,
              updateChange => setShowEnvDialog(_ => Some(updateChange)),
            ),
          |],
        )
      },
      (setShowEnvDialog, setShowSigDialog),
    );

  <div className="box">
    <HFlex style=Css.[marginBottom(px(0))]>
      <Modal isOpen={showEnvDialog != None} onRequestClose={_ => setShowEnvDialog(_ => None)}>
        <Forms.Env env seed setShow=setShowEnvDialog />
      </Modal>
      <Modal isOpen={showSigDialog != None} onRequestClose={_ => setShowSigDialog(_ => None)}>
        <Forms.NoData db_name="bactsig" setShow=setShowSigDialog />
      </Modal>
      <div>
        <h5 className="title nice-title is-5"> "Bact sigs"->React.string </h5>
        <SignaturesTable update globalActions=sigGlobalActions />
      </div>
      <div>
        <h5 className="title nice-title is-5"> "Environment"->React.string </h5>
        <EnvsTable update globalActions=envGlobalActions />
      </div>
    </HFlex>
  </div>;
};
