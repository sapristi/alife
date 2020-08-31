open Acid_types;
open Client_types;
open Belt;
open Utils;
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
    prev_state->ArrayExt.reinsert(
      ~value=Item.ProtElem(id, acid),
      ~place=placement,
    )
  | DndAction(Some(NewContainer(Source(_, acid), AcidsList, placement))) =>
    ArrayExt.insert(
      prev_state,
      ~value=ProtElem(DndId.make(), acid),
      ~place=placement,
    )
  | UpdateAction(index, new_acid) =>
    ArrayExt.replace(prev_state, index, ProtElem(DndId.make(), new_acid))
  | DeleteAction(index) => ArrayExt.delete(prev_state, index)
  | InitAction(proteine) =>
    Array.map(proteine, acid => Item.ProtElem(DndId.make(), acid))
  | _ => prev_state
  };
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
    Molbuilder__actions.commitProteine(
      storeDispatch,
      Array.map(acidItems, Item.to_acid),
    );
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

  Js.log2("Rendering Acids panel", acidItems);

  <MolBuilderDnd.DndManager
    onDragStart={(~itemId as _itemId) =>
      [%log.info "AppHook"; ("Event", "DragStart"); ("ItemId", _itemId)]
    }
    onDropStart={(~itemId as _itemId) =>
      [%log.info "AppHook"; ("Event", "DropStart"); ("ItemId", _itemId)]
    }
    onDropEnd={(~itemId as _itemId) =>
      [%log.info "AppHook"; ("Event", "DropEnd"); ("ItemId", _itemId)]
    }
    onReorder={res => dispatchAcidItems(DndAction(res))}>
    <div className="panel" style=Css.(style([minWidth(px(400))]))>
      <HFlex
        className="panel-heading"
        style=Css.[alignItems(center), justifyContent(spaceBetween)]>
        "Proteine"->React.string
        <HFlex>
          <button className="button" onClick=commitProteine>
            "Commit"->React.string
          </button>
          <Input.Checkbox
            state=autocommit
            setState=setAutocommit
            label="Auto-commit"
            id="mol_auto_commit"
          />
        </HFlex>
      </HFlex>
      <MolBuilderDnd.DroppableContainer
        id=AcidsList axis=Y className=Container.style>
        <ul>
          {Array.mapWithIndex(acidItems, (index, elem) =>
             <li key={elem->Item.to_string}>
               <MolBuilderDnd.DraggableItem
                 id=elem containerId=AcidsList index>
                 {`Children(
                    switch (elem) {
                    | Source(_) => React.null
                    | ProtElem(id, acid) =>
                      <EditableAcid
                        id
                        acid
                        update={new_acid =>
                          dispatchAcidItems(UpdateAction(index, new_acid))
                        }
                        delete={_ => dispatchAcidItems(DeleteAction(index))}
                      />
                    },
                  )}
               </MolBuilderDnd.DraggableItem>
             </li>
           )
           ->React.array}
        </ul>
      </MolBuilderDnd.DroppableContainer>
    </div>
    <AcidsPicker />
  </MolBuilderDnd.DndManager>;
};
