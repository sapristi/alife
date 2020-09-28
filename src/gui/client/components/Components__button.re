module Button = {
  [@react.component]
  let make = (~children, ~classNames=[], ~onClick=_ => (), ~styles=[], ~disabled=false) => {
    <button
      className={Cn.fromList(["button", ...classNames])}
      onClick
      disabled
      style={Css.style(styles)}>
      children
    </button>;
  };
};
module ButtonIcon = {
  [@react.component]
  let make = (~children, ~classNames=[], ~onClick=_ => (), ~styles=[]) => {
    <Button classNames onClick styles> <span className="icon"> children </span> </Button>;
  };
};
