module Button = {
  [@react.component]
  let make = (~children, ~classNames=[], ~onClick, ~styles=[]) => {
    <button
      className={Cn.fromList(["button", ...classNames])}
      onClick
      style={Css.style(styles)}>
      children
    </button>;
  };
};
module ButtonIcon = {
  [@react.component]
  let make = (~children, ~classNames=[], ~onClick, ~styles=[]) => {
    <Button classNames onClick styles>
      <span className="icon"> children </span>
    </Button>;
  };
};
