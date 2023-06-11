module HFlex = {
  let hflex = Css.[display(flexBox)];

  [@react.component]
  let make = (~children, ~style=[], ~className="", ~onClick=None) => {
    <div style={Css.style(hflex @ style)} className ?onClick> children </div>;
  };
};

module VFlex = {
  let vflex = Css.[display(flexBox), flexDirection(column)];

  [@react.component]
  let make = (~children, ~style=[], ~className="", ~onClick=None) => {
    <div style={Css.style(vflex @ style)} className ?onClick> children </div>;
  };
};
