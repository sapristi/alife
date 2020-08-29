open Acid_types;
open Client_types;
open Belt;
open Utils;
open Molbuilder__dnd;

module EditableAcid = Molbuilder__editable_acids;
module AcidsPicker = Molbuilder__acids_picker;

/* open Belt; */

type state = {
  acidItems: array(Item.t),
  other: unit,
};

type action =
  | DndAction(Dnd.result(Item.t, Container.t))
  | UpdateAction(int, acid)
  | DeleteAction(int);

[@react.component]
let make = (~commit) => {
  let reducer = (prev_state, action: action) => {
    switch (action) {
    | DndAction(Some(SameContainer(ProtElem(id, acid), placement))) => {
        ...prev_state,
        acidItems:
          prev_state.acidItems
          ->ArrayExt.reinsert(
              ~value=Item.ProtElem(id, acid),
              ~place=placement,
            ),
      }
    | DndAction(Some(NewContainer(Source(_, acid), AcidsList, placement))) => {
        ...prev_state,
        acidItems:
          ArrayExt.insert(
            prev_state.acidItems,
            ~value=ProtElem(DndId.make(), acid),
            ~place=placement,
          ),
      }
    | UpdateAction(index, new_acid) => {
        ...prev_state,
        acidItems:
          ArrayExt.replace(
            prev_state.acidItems,
            index,
            ProtElem(DndId.make(), new_acid),
          ),
      }
    | DeleteAction(index) => {
        ...prev_state,
        acidItems: ArrayExt.delete(prev_state.acidItems, index),
      }
    | _ => prev_state
    };
  };

  let (state, dispatchState) =
    React.useReducer(reducer, {acidItems: [||], other: ()});

  Js.log2("Acids", state.acidItems);

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
    onReorder={res => dispatchState(DndAction(res))}>
    <AcidsPicker />
    <div className="box" style=Css.(style([minWidth(px(400))]))>
      <div>
        <button
          className="button"
          onClick={_ => commit(Array.map(state.acidItems, Item.to_acid))}>
          "Commit"->React.string
        </button>
      </div>
      <MolBuilderDnd.DroppableContainer
        id=AcidsList axis=Y className=Container.style>
        <ul>
          {Array.mapWithIndex(state.acidItems, (index, elem) =>
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
                          dispatchState(UpdateAction(index, new_acid))
                        }
                        delete={_ => dispatchState(DeleteAction(index))}
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
  </MolBuilderDnd.DndManager>;
};
