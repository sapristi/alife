open Utils;

module Tabs = {
  [@react.component]
  let make = (~tabs, ~activeTab, ~setActiveTab) => {
    let getClassName = t =>
      if (t == activeTab) {
        "is-active";
      } else {
        "";
      };

    <div className="tabs">
      <ul>
        {List.mapi(
           (i, (value, display)) =>
             <li className={getClassName(value)} key={string_of_int(i)}>
               <a onClick={_ => setActiveTab(value)}> display </a>
             </li>,
           tabs,
         )
         ->Generics.react_list}
      </ul>
    </div>;
  };
};

module HFlex = Components__flex.HFlex;
module VFlex = Components__flex.VFlex;

module ArrayExt = Utils__ArrayExt;

module Input = Components__input;

module Icons = Components__icons;
module Panel = Components__panel;

module Button = Components__button.Button;
module ButtonIcon = Components__button.ButtonIcon;

module Modal = Components__modal;

module Table = Components__table;
/* module Tooltip = { */
/*   [@react.component] [@bs.module "rc-tooltip"] */
/*   external make: */
/*     ( */
/*       ~placement: string=?, */
/*       ~children: React.element, */
/*       ~overlay: React.element, */
/*       ~trigger: array(string), */
/*       ~destroyTooltipOnHide: bool */
/*     ) => */
/*     React.element = */
/*     "default"; */
/* }; */

module Tooltip = {
  [@react.component]
  let make = (~children, overlay) => {};
};

module MolTooltip = {
  [@react.component]
  let make = (~mol) => {
    <div
      style=Css.(
        style([
          /* maxWidth(vw(30.)), */
          /* backgroundColor(white), */
          wordBreak(breakAll),
        ])
      )
      className="tooltiptext">
      mol->React.string
    </div>;
  };
};

module Molecule = {
  [@react.component]
  let make = (~mol) => {
    <div
      className="tooltip"
      style=Css.(
        style([
          textOverflow(ellipsis),
          overflow(hidden),
          /* wordBreak(breakAll), */
          /* maxWidth(vw(60.)), */
        ])
      )>
      <MolTooltip mol />
      mol->React.string
    </div>;
  };
};
module Loader = Components__loader;
