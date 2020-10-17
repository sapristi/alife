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
  let defaultStyle: style = {
    content:
      Css.[
        width(vw(50.)),
        height(pct(70.)),
        left(vw(25.)),
        right(vw(25.)),
    top(pct(15.)),
    zIndex(10)
      ],
    overlay: Css.[],
  };

  let styleInner: ModalImported.style =
    Belt.Option.getWithDefault(style, defaultStyle)
    ->(
        (s) => (
          {
            overlay: Css.style(defaultStyle.overlay @ s.overlay),
            content: Css.style(defaultStyle.content @ s.content),
          }: ModalImported.style
        )
      );
  <ModalImported isOpen onRequestClose ariaHideApp=false style=styleInner>
    children
  </ModalImported>;
};
