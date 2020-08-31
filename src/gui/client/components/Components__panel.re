[@react.component]
let make = (~children) => {
  let (opened, setOpen) = React.useState(() => true);
  <div className="panel">
    <div className="panel-heading"> {fst(children)} </div>
    {if (opened) {
       snd(children);
     } else {
       <div />;
     }}
  </div>;
};
