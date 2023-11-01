module Flex = Components__flex;
module Button = Components__button.Button;
module ButtonIcon = Components__button.ButtonIcon;
module Icons = Components__icons;

type column('a) = {
  style: list(Css.rule),
  header: unit => React.element,
  makeCell: 'a => React.element,
  key: string,
  sort: option(('a, 'a) => int),
};

module BiChevron = {
  [@react.component]
  let make = (~color: option(string)=?, ~size: option(int)=?) => {
    <Flex.VFlex>
      <Icons.ChevronUp ?color ?size />
      <Icons.ChevronDown ?color ?size />
    </Flex.VFlex>;
  };
};

type sort_mode =
  | NoSort
  | Desc
  | Asc;

let cycle = sort_mode =>
  switch (sort_mode) {
  | NoSort => Desc
  | Desc => Asc
  | Asc => NoSort
  };

module SortHeaderSortable = {
  [@react.component]
  let make = (~ckey, ~cmp, ~sort, ~setSort) => {
    let (current_sort_key, sort_mode, _) =
      Belt.Option.getWithDefault(sort, ("nokey", NoSort, cmp));
    let cSortMode =
      if (ckey != current_sort_key) {
        NoSort;
      } else {
        sort_mode;
      };

    let sortAction = () => {
      setSort(_ => Some((ckey, cycle(cSortMode), cmp)));
    };

    <Flex.HFlex>
      {switch (cSortMode) {
       | NoSort => <Button onClick={_ => sortAction()}> <BiChevron size=10 /> </Button>
       | Desc => <Button onClick={_ => sortAction()}> <Icons.ChevronDown size=10/> </Button>
       | Asc => <Button onClick={_ => sortAction()}> <Icons.ChevronUp size=10/> </Button>
       }}
    </Flex.HFlex>;
  };
};

module SortHeader = {
  [@react.component]
  let make = (~column, ~sort, ~setSort) => {
    switch (column.sort) {
    | None => React.null
    | Some(cmp) => <SortHeaderSortable ckey={column.key} cmp sort setSort />
    };
  };
};

[@react.component]
let make = (~columns: array(column('a)), ~data, ~getRowKey, ~styles=[]) => {
  let (sortState, setSortState) = React.useState(() => None);

  switch (sortState) {
  | None => ()
  | Some((_, mode, cmp)) =>
    switch (mode) {
    | NoSort => ()
    | Asc => Array.sort(cmp, data)
    | Desc => Array.sort((x, y) => - cmp(x, y), data)
    }
  };

  <table
    style=Css.(style([tableLayout(fixed), ...styles]))
    className="table is-fullwidth is-striped">
    <colgroup>
      {Array.map(
         column => <col span=1 style={Css.style(column.style)} key={column.key} />,
         columns,
       )
       ->React.array}
    </colgroup>
    <thead>
      <tr>
        {Array.map(
           column =>
             <th key={column.key}>
               <Flex.HFlex style=Css.[alignItems(center)]>
                 {column.header()}
                 <SortHeader column sort=sortState setSort=setSortState />
               </Flex.HFlex>
             </th>,
           columns,
         )
         ->React.array}
      </tr>
    </thead>
    <tbody>
      {Array.map(
         row =>
           <tr key={getRowKey(row)}>
             {Array.map(column => <td key={column.key}> {column.makeCell(row)} </td>, columns)
              ->React.array}
           </tr>,
         data,
       )
       ->React.array}
    </tbody>
  </table>;
};
