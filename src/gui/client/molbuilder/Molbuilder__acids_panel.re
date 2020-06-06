open Acid_types;
open Client_types;
open Belt;
open Utils;

module EditableAcid = Molbuilder__editable_acids;

module Id = {
  type t = int;
  let current = ref(0);

  let make = () => {
    current := 1 + current^;
    current^ - 1;
  };
};

/* open Belt; */
module Item = {
  type t =
    | Source(Id.t, acid)
    | ProtElem(Id.t, acid);
  let eq = (x1, x2) =>
    switch (x1, x2) {
    | (Source(id1, _), Source(id2, _)) => id1 === id2
    | (ProtElem(id1, _), ProtElem(id2, _)) => id1 === id2
    | _ => false
    };
  let cmp = (x1, x2) =>
    switch (x1, x2) {
    | (Source(id1, _), Source(id2, _)) => compare(id1, id2)
    | (ProtElem(id1, _), ProtElem(id2, _)) => compare(id1, id2)
    | (Source(_), ProtElem(_)) => (-1)
    | (ProtElem(_), Source(_)) => 1
    };
  let to_string = item =>
    switch (item) {
    | Source(id, acid) => "S" ++ string_of_int(id) ++ Chemistry.acid_to_descr(acid)
    | ProtElem(id, acid) => "P" ++ string_of_int(id) ++ Chemistry.acid_to_descr(acid)
    };

  let to_component = to_string;
};

/* let acidMap = Map.make(~id=(module Item.Comparable)); */
/* type t = Map.t(Item.t, AcidItem.t, Comparable.identity); */

module Container = {
  type t =
    | AcidsSource
    | AcidsList;
  let eq = (x1, x2) => x1 === x2; // or more concise: let eq = (==);
  let cmp = compare; // default comparator from Pervasives module

  let style = (~draggingOver) => if (draggingOver) {"dnd-container-hovered"} else {"dnd-container"};
};

module MolBuilder = Dnd.Make(Item, Container);

let acid_to_draggable = (acid, id) => {
  <MolBuilder.DraggableItem id={Source(id, acid)} containerId=AcidsSource index=id>
    {`Children(Chemistry.acid_to_descr(acid)->React.string)}
  </MolBuilder.DraggableItem>;
};

type state = {
  acidItems: array(Item.t),
  other: unit,
};

type action =
  | DndAction(Dnd.result(Item.t, Container.t))
  | UpdateAction(int, acid);

[@react.component]
let make = () => {
  let reducer = (prev_state, action: action) => {
    switch (action) {
    | DndAction(Some(SameContainer(ProtElem(id, acid), placement))) => {
        ...prev_state,
        acidItems: prev_state.acidItems->ArrayExt.reinsert(~value=Item.ProtElem(id, acid), ~place=placement),
      }
    | DndAction(Some(NewContainer(Source(_, acid), AcidsList, placement))) => {
        ...prev_state,
        acidItems: ArrayExt.insert(prev_state.acidItems, ~value=ProtElem(Id.make(), acid), ~place=placement),
      }
    | UpdateAction(index, new_acid) => {
        ...prev_state,
        acidItems: ArrayExt.replace(prev_state.acidItems, index, ProtElem(Id.make(), new_acid)),
      }
    | _ => prev_state
    };
  };

  let (state, dispatchState) = React.useReducer(reducer, {acidItems: [||], other: ()});

  Js.log2("Acids", state.acidItems);

  <MolBuilder.DndManager
    onDragStart={(~itemId as _itemId) => [%log.info "AppHook"; ("Event", "DragStart"); ("ItemId", _itemId)]}
    onDropStart={(~itemId as _itemId) => [%log.info "AppHook"; ("Event", "DropStart"); ("ItemId", _itemId)]}
    onDropEnd={(~itemId as _itemId) => [%log.info "AppHook"; ("Event", "DropEnd"); ("ItemId", _itemId)]}
    onReorder={res => dispatchState(DndAction(res))}>
    <div className="panel">
      <p className="panel-heading"> "Acids"->React.string </p>
      <div className="panel-block content">
        <MolBuilder.DroppableContainer id=AcidsSource axis=Y accept={_ => false}>
          <ul>
            <li> {acid_to_draggable(Place, 0)} </li>
            <li>
              "Input Arcs"->React.string
              <ul>
                {List.mapWithIndex(
                   List.mapWithIndex(Examples.input_arcs, (index, acid) => acid_to_draggable(acid, index + 1)),
                   (index, x) => {
                   <li key={index->string_of_int}> x </li>
                 })
                 ->Generics.react_list}
              </ul>
            </li>
            <li>
              "Output Arcs"->React.string
              <ul>
                {List.mapWithIndex(
                   List.mapWithIndex(Examples.output_arcs, (index, acid) =>
                     acid_to_draggable(acid, index + 1 + List.length(Examples.input_arcs))
                   ),
                   (index, x) =>
                   <li key={index->string_of_int}> x </li>
                 )
                 ->Generics.react_list}
              </ul>
            </li>
            <li>
              "Extensions"->React.string
              <ul>
                {List.mapWithIndex(
                   List.mapWithIndex(Examples.extensions, (index, acid) =>
                     acid_to_draggable(
                       acid,
                       index + 1 + List.length(Examples.input_arcs) + List.length(Examples.output_arcs),
                     )
                   ),
                   (index, x) =>
                   <li key={index->string_of_int}> x </li>
                 )
                 ->Generics.react_list}
              </ul>
            </li>
          </ul>
        </MolBuilder.DroppableContainer>
      </div>
    </div>
    <div className="box" style=Css.(style([minWidth(px(200))]))>
      <MolBuilder.DroppableContainer id=AcidsList axis=Y className=Container.style>
        <ul>
          {Array.mapWithIndex(state.acidItems, (index, elem) =>
             <li key={elem->Item.to_string}>
               <MolBuilder.DraggableItem id=elem containerId=AcidsList index>
                 {`Children(
                    switch (elem) {
                    | Source(_) => React.null
                    | ProtElem(id, acid) =>
                      <EditableAcid id acid update={new_acid => dispatchState(UpdateAction(index, new_acid))} />
                    },
                  )}
               </MolBuilder.DraggableItem>
             </li>
           )
           ->React.array}
        </ul>
      </MolBuilder.DroppableContainer>
    </div>
  </MolBuilder.DndManager>;
};
