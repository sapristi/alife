open Acid_types;
open Client_types;
open Belt;
open Molbuilder__dnd;
open Components;

module EditableAcid = Molbuilder__editable_acids;
module AcidsPicker = Molbuilder__acids_picker;

/* open Belt; */

type acidItemsState = array(Item.t);

type action =
  | DndAction(Dnd.result(Item.t, Container.t))
  | UpdateAction(int, acid)
  | DeleteAction(int)
  | InitAction(proteine);

let proteine_selector = (state: Store.appState) => state.molbuilder.proteine;
let reducer = (prev_state, action: action) => {
  switch (action) {
  | DndAction(Some(SameContainer(ProtElem(id, acid), placement))) =>
    prev_state->ArrayExt.reinsert(~value=Item.ProtElem(id, acid), ~place=placement)
  | DndAction(Some(NewContainer(Source(_, acid), AcidsList, placement))) =>
    ArrayExt.insert(prev_state, ~value=ProtElem(DndId.make(), acid), ~place=placement)
  | UpdateAction(index, new_acid) =>
    ArrayExt.replace(prev_state, index, ProtElem(DndId.make(), new_acid))
  | DeleteAction(index) => ArrayExt.delete(prev_state, index)
  | InitAction(proteine) => Array.map(proteine, acid => Item.ProtElem(DndId.make(), acid))
  | _ => prev_state
  };
};

let onDragStart = ActionsDebug.debug("DragStart");
let onDropStart = ActionsDebug.debug("DropStart");
let onDropEnd = ActionsDebug.debug("DropEnd");

module DraggableEditableAcid = {
  [@react.component]
  let make = React.memo((~index, ~elem, ~dispatchAcidItems) => {
    let updateDraggable =
      React.useCallback1(
        new_acid => dispatchAcidItems(UpdateAction(index, new_acid)),
        [|dispatchAcidItems|],
      );
    let deleteDraggable =
      React.useCallback1(_ => dispatchAcidItems(DeleteAction(index)), [|dispatchAcidItems|]);

    switch (elem) {
    | Item.Source(_) => React.null
    | ProtElem(_, acid) => <EditableAcid acid update=updateDraggable delete=deleteDraggable />
    };
  });
};

[@react.component]
let make = () => {
  let storeDispatch = Store.useDispatch();
  let (acidItems, dispatchAcidItems) = React.useReducer(reducer, [||]);
  let (autocommit, setAutocommit) = React.useState(() => false);
  let proteine = Store.useSelector(proteine_selector);
  React.useEffect1(
    () => {
      Js.log3("Proteine changed", proteine, proteine_encode(proteine));
      dispatchAcidItems(InitAction(proteine));
      None;
    },
    [|Js.Json.stringifyAny(proteine)|],
  );

  let commitProteine = _ =>
    Molbuilder__actions.commitProteine(storeDispatch, Array.map(acidItems, Item.to_acid));
  React.useEffect1(
    () => {
      Js.log3("AcidItems changed", autocommit, acidItems);
      if (autocommit) {
        commitProteine();
      };
      None;
    },
    [|Js.Json.stringifyAny(acidItems)|],
  );

  let onReorder =
    React.useCallback1(res => dispatchAcidItems(DndAction(res)), [|dispatchAcidItems|]);

  Js.log2("Rendering Acids panel", acidItems);

  <MolBuilderDnd.DndManager onDragStart onDropStart onDropEnd onReorder>
    <div className="panel" style=Css.(style([minWidth(px(600))]))>
      <HFlex
        className="panel-heading"
        style=Css.[alignItems(center), justifyContent(spaceBetween)]>
        "Proteine"->React.string
        <HFlex>
          <button className="button" onClick=commitProteine> "Commit"->React.string </button>
          <Input.Checkbox
            state=autocommit
            setState=setAutocommit
            label="Auto-commit"
            id="mol_auto_commit"
          />
        </HFlex>
      </HFlex>
      <HFlex style=Css.[height(pct(100.)), maxHeight(px(700))]>
        <MolBuilderDnd.DroppableContainer id=AcidsList axis=Y className=Container.style>
          <ul>
            {Array.mapWithIndex(acidItems, (index, elem) =>
               <li key={elem->Item.to_string}>
                 <MolBuilderDnd.DraggableItem id=elem containerId=AcidsList index>
                   {`Children(<DraggableEditableAcid index elem dispatchAcidItems />)}
                 </MolBuilderDnd.DraggableItem>
               </li>
             )
             ->React.array}
          </ul>
        </MolBuilderDnd.DroppableContainer>
        <AcidsPicker />
      </HFlex>
    </div>
  </MolBuilderDnd.DndManager>;
};
