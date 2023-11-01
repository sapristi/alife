open Client_types;
open Types.Acid;
open Molbuilder__dnd;
open Belt;
open Utils;

let acid_to_draggable = (acid, id) => {
  <MolBuilderDnd.DraggableItem
    id={Source(id, acid)} containerId=AcidsSource index=id>
    {`Children(
       <button className="button is-small is-primary is-light">
         {acid->Chemistry.acid_to_descr->React.string}
       </button>,
     )}
  </MolBuilderDnd.DraggableItem>;
};

[@react.component]
let make = () => {
  <div className="card" style=Css.(style([overflow(auto), flexShrink(0.)]))>
    <header className="card-header">
      <p className="card-header-title"> "Acids"->React.string </p>
    </header>
    <div className="panel-block content">
      <MolBuilderDnd.DroppableContainer
        id=AcidsSource axis=Y accept={_ => false}>
        <ul>
          <li> {acid_to_draggable(Place, 0)} </li>
          <li>
            "Input Arcs"->React.string
            <ul>
              {List.mapWithIndex(
                 List.mapWithIndex(Examples.input_arcs, (index, acid) =>
                   acid_to_draggable(acid, index + 1)
                 ),
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
                   acid_to_draggable(
                     acid,
                     index + 1 + List.length(Examples.input_arcs),
                   )
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
                     index
                     + 1
                     + List.length(Examples.input_arcs)
                     + List.length(Examples.output_arcs),
                   )
                 ),
                 (index, x) =>
                 <li key={index->string_of_int}> x </li>
               )
               ->Generics.react_list}
            </ul>
          </li>
        </ul>
      </MolBuilderDnd.DroppableContainer>
    </div>
  </div>;
};
