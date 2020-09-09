module HFlex = {
  let hflex = Css.[display(flexBox)];

  [@react.component]
  let make = (~children, ~style=[], ~className="") => {
    <div style={Css.style(hflex @ style)} className> children </div>;
  };
};

module VFlex = {
  let vflex = Css.[display(flexBox), flexDirection(column)];

  [@react.component]
  let make = (~children, ~style=[], ~className="") => {
    <div style={Css.style(vflex @ style)} className> children </div>;
  };
};
