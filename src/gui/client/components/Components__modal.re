module ModalImported = {
  type style = {
    overlay: ReactDOMStyle.t,
    content: ReactDOMStyle.t,
  };

  [@react.component] [@bs.module]
  external make:
    (
      ~isOpen: bool,
      ~onRequestClose: unit => unit,
      ~children: React.element,
      ~ariaHideApp: bool,
      ~style: style
    ) =>
    React.element =
    "react-modal";
};

type style = {
  overlay: list(Css_Core.rule),
  content: list(Css_Core.rule),
};


[@react.component]
let make = (~isOpen, ~onRequestClose, ~children, ~style=?) => {
  let styleInner: ModalImported.style =
    switch (style) {
    | None => {overlay: Css.style([]), content: Css.style([])}
    | Some(style') => {
        overlay: Css.style(style'.overlay),
        content: Css.style(style'.content),
      }
    };
  <ModalImported isOpen onRequestClose ariaHideApp=false style=styleInner>
    children
  </ModalImported>;
};
