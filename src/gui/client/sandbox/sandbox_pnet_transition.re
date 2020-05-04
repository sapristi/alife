open Client_types;
open Client_utils;

[@react.component]
let make = (~pnet: Petri_net.petri_net, ~transition_id, ~dispatch) => {
  let transition = pnet.transitions[transition_id];

  let launch = _ => {
    YaacApi.request(
      Fetch.Put,
      "/sandbox/amol/" ++ pnet.molecule ++ "/pnet/" ++ pnet.id->string_of_int,
      ~payload=pnet_action_encode(Launch_transition(transition_id)),
      ~side_effect=() => dispatch(SwitchUpdate),
      (),
    )
    ->ignore;
  };

  <div>
    <div className="message is-info">
      <div className="message-header"> "Transition"->React.string </div>
      <div className="message-body content">
        (
          if (transition.launchable) {
            "Launchable";
          } else {
            "Not launchable";
          }
        )
        ->React.string
        <button className="button" disabled=true onClick=launch> "Launch (needs debug)"->React.string </button>
        <p>
          "Incoming arcs:"->React.string
          {List.map(
             ia => <li> Petri_net.(input_arc_to_descr(ia.iatype))->React.string </li>,
             transition.input_arcs,
           )
           ->Generics.react_list}
        </p>
        <p>
          "Outgoing arcs:"->React.string
          {List.map(
             oa => <li> Petri_net.(output_arc_to_descr(oa.oatype))->React.string </li>,
             transition.output_arcs,
           )
           ->Generics.react_list}
        </p>
      </div>
    </div>
  </div>;
};
