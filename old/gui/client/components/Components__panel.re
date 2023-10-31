module Simple = {
  [@react.component]
  let make = (~title, ~body, ~styles) => {
    <div className="panel" style=Css.(style(styles))>
      <div className="panel-heading"> title </div>
      body
    </div>;
  };
};

module Collapsable = {
  [@react.component]
  let make = (~title, ~body, ~styles) => {
    let (opened, setOpen) = React.useState(() => true);
    let toggleOpen = _ => setOpen(o => !o);
    let icon =
      if (opened) {
        <Components__icons.ChevronUp />;
      } else {
        <Components__icons.ChevronDown />;
      };

    let title' =
      <Components__flex.HFlex style=Css.[alignItems(center)] onClick={Some(toggleOpen)}>
        <Components__button.ButtonIcon styles=Css.[marginRight(px(10))]>
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
    <Simple title=title' body=body' styles />;
  };
};

[@react.component]
let make = (~children, ~collapsable=false, ~styles=[]) => {
  let title = fst(children);
  let body = snd(children);

  if (collapsable) {
    <Collapsable title body styles />;
  } else {
    <Simple title body styles />;
  };
};

module Tabs = {
  [@react.component]
  let make = (~tabs, ~activeTab, ~setActiveTab) => {
    <p className="panel-tabs">
      {Array.map(
         ((tab, tab_s)) =>
           <a
             key=tab_s
             className={Cn.on("is-active", tab === activeTab)}
             onClick={_ => setActiveTab(tab)}>
             tab_s->React.string
           </a>,
         tabs,
       )
       ->React.array}
    </p>;
  };
};
