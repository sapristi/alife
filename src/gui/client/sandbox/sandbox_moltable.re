open Client_utils;

let make_width = (wpct: float) => Css.(style([width(pct(wpct))]));

[@react.component]
let make =
    (
      ~col_widths,
      ~headers,
      ~data,
      ~make_row,
      ~selected,
      ~setSelected,
      ~get_key,
    ) => {
  React.useEffect1(
    () => {
      switch (selected) {
      | None => ()
      | Some(mol) =>
        switch (List.find_opt(x => get_key(x) == get_key(mol), data)) {
        | None => setSelected(_ => None)
        | _ => ()
        }
      };
      None;
    },
    [|data|],
  );

  let tr_classname = mol =>
    if (Some(mol) == selected) {
      "is-selected";
    } else {
      "";
    };

  let handleSelect = clicked =>
    setSelected(prev =>
      if (prev == Some(clicked)) {
        None;
      } else {
        Some(clicked);
      }
    );

  <table
    className="table is-fullwidth is-striped"
    style=Css.(style([tableLayout(fixed)]))>
    <colgroup>
      {Generics.react_list(
         List.mapi(
           (i, w) =>
             <col span=1 style={make_width(w)} key={i->Js.Int.toString} />,
           col_widths,
         ),
       )}
    </colgroup>
    <thead>
      <tr>
        {Generics.react_list(
           List.map(h => <th key=h> h->React.string </th>, headers),
         )}
      </tr>
    </thead>
    <tbody>
      {Generics.react_list(
         List.map(
           mol =>
             <tr
               key={get_key(mol)}
               onClick={_ => handleSelect(mol)}
               className={tr_classname(mol)}>
               {make_row(mol)}
             </tr>,
           data,
         ),
       )}
    </tbody>
  </table>;
};
