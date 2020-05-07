/* open Client_utils; */
open Client_types;

type state = {
  mol: Petri_net.molecule,
  pnet: option(Petri_net.petri_net),
  prot: string,
};

let initial_state = {mol: "", pnet: None, prot: ""};

[@react.component]
let make = () => {
  let (state, dispatch) = React.useReducer((x, y) => x, initial_state);
  let containerRef: React.Ref.t(Js.Nullable.t(Dom.element)) = React.useRef(Js.Nullable.null);

  <Components.VFlex>
    <h1 className="title"> "Molbuilder"->React.string </h1>
    <section className="section">
      <div ref={ReactDOMRe.Ref.domRef(containerRef)} style=Css.(style([width(px(200)), height(px(200))])) />
    </section>
    <section className="section" />
  </Components.VFlex>;
};
