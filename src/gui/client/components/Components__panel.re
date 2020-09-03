module Panel_simple = {
  [@react.component]
  let make = (~title, ~body, ~styles) => {
    <div className="panel" style=Css.(style(styles))>
      <div className="panel-heading"> title </div>
      body
    </div>;
  };
};

module Panel_collapsable = {
  [@react.component]
  let make = (~title, ~body, ~styles) => {
    let (opened, setOpen) = React.useState(() => true);
    let toggleOpen = _ => setOpen(o => !o);
    let icon =
      if (opened) {
        <Components__icons.ChevronRight />;
      } else {
        <Components__icons.ChevronDown />;
      };

    let title' =
      <Components__flex.HFlex style=Css.[alignItems(center)]>
        <Components__button.ButtonIcon
          onClick=toggleOpen styles=Css.[marginRight(px(10))]>
          icon
        </Components__button.ButtonIcon>
        title
      </Components__flex.HFlex>;
    let body' =
      if (opened) {
        body;
      } else {
        <div />;
      };
    <Panel_simple title=title' body=body' styles />;
  };
};

[@react.component]
let make = (~children, ~collapsable=false, ~styles=[]) => {
  let title = fst(children);
  let body = snd(children);

  if (collapsable) {
    <Panel_collapsable title body styles />;
  } else {
    <Panel_simple title body styles />;
  };
};
