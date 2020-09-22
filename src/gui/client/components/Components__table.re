module MakeTable = (Spec: {
                      type rowtype;
                      let getRowKey: rowtype => string;
                    }) => {
  type column = {
    style: list(Css.rule),
    header: unit => React.element,
    makeCell: Spec.rowtype => React.element,
    key: string,
  };

  [@react.component]
  let make = (~columns, ~data, ~styles) => {
    <table style=Css.(style([tableLayout(fixed), ...styles])) className="table is-fullwidth is-striped">
      <colgroup>
        {Array.map(
           column => <col span=1 style={Css.style(column.style)} key={column.key} />,
           columns,
         )
         ->React.array}
      </colgroup>
      <thead>
        <tr>
          {Array.map(column => <th key={column.key}> {column.header()} </th>, columns)
           ->React.array}
        </tr>
      </thead>
      <tbody>
        {Array.map(
           row =>
             <tr key={Spec.getRowKey(row)}>
               {Array.map(column => column.makeCell(row), columns)->React.array}
             </tr>,
           data,
         )
         ->React.array}
      </tbody>
    </table>;
  };
};

type column('a) = {
  style: list(Css.rule),
  header: unit => React.element,
  makeCell: 'a => React.element,
  key: string,
};

[@react.component]
  let make = (~columns: array(column('a)), ~data, ~getRowKey, ~styles=[]) => {
  <table style=Css.(style([tableLayout(fixed), ...styles])) className="table is-fullwidth is-striped">
    <colgroup>
      {Array.map(
         column => <col span=1 style={Css.style(column.style)} key={column.key} />,
         columns,
       )
       ->React.array}
    </colgroup>
    <thead>
      <tr>
        {Array.map(column => <th key={column.key}> {column.header()} </th>, columns)
         ->React.array}
      </tr>
    </thead>
    <tbody>
      {Array.map(
         row =>
           <tr key={getRowKey(row)}>
             {Array.map(column => <td>{column.makeCell(row)}</td>, columns)->React.array}
           </tr>,
         data,
       )
       ->React.array}
    </tbody>
  </table>;
};
