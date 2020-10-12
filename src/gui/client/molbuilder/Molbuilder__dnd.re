open Client_types;
open Acid_types;

module DndId = {
  type t = int;
  let current = ref(0);

  let make = () => {
    current := 1 + current^;
    current^ - 1;
  };
};

module Item = {
  type t =
    | Source(DndId.t, acid)
    | ProtElem(DndId.t, acid);
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
    | Source(id, acid) =>
      "S" ++ string_of_int(id) ++ Chemistry.acid_to_descr(acid)
    | ProtElem(id, acid) =>
      "P" ++ string_of_int(id) ++ Chemistry.acid_to_descr(acid)
    };

  let to_component = to_string;
  let to_acid = item =>
    switch (item) {
    | Source(_, acid) => acid
    | ProtElem(_, acid) => acid
    };
};

/* let acidMap = Map.make(~id=(module Item.Comparable)); */
/* type t = Map.t(Item.t, AcidItem.t, Comparable.identity); */

module Container = {
  type t =
    | AcidsSource
    | AcidsList;
  let eq = (x1, x2) => x1 === x2; // or more concise: let eq = (==);
  let cmp = compare; // default comparator from Pervasives module

  let style = (~draggingOver) =>
    if (draggingOver) {"dnd-container-hovered card"} else {"dnd-container card"};
};

module MolBuilderDnd = Dnd.Make(Item, Container);
