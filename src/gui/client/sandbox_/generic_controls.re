module EnvControls = {
  [@react.component]
  let make = (~env: Client_types.environment) => {
    <div>
      <select className="ui dropdown">
        <option value={env.break_rate}> {React.string("break rate")} </option>
        <option value={env.collision_rate}>
          {React.string("collision rate")}
        </option>
        <option value={env.grab_rate}> {React.string("grab rate")} </option>
        <option value={env.transition_rate}>
          {React.string("transition rate")}
        </option>
      </select>
      <button className="ui primary button">
        {React.string("Load state")}
      </button>
    </div>;
  };
};

module StateLoader = {
  [@decco]
  type data = list(string);

  [@react.component]
  let make = () => {
    let (values, setValues) = React.useState(_ => []);

    Client_utils.get("/api/sandbox/state", res => {
      switch (data_decode(res)) {
      | Ok(data) =>
        if (List.length(values) == 0) {
          setValues(_ => data);
        };
        Js.log(data);
      | Error(e) => ()
      }
    });
    let (state, setState) = React.useReducer((_, v) => v, "");

    let handleChange = (e: ReactEvent.Form.t, _) => {
      setState(e->ReactEvent.Form.target##value);
    };

    <div>
      <MaterialUi.Select value={`String(state)} onChange=handleChange>
        {ReasonReact.array(
           Array.of_list(
             List.map(
               v =>
                 <MaterialUi.MenuItem value={`String(v)}>
                   {React.string(v)}
                 </MaterialUi.MenuItem>,
               values,
             ),
           ),
         )}
      </MaterialUi.Select>
      <button className="ui primary button">
        {React.string("Load state")}
      </button>
    </div>;
  };
};

[@react.component]
let make = (~env, ~update) => {
  MaterialUi.(
    <div className="ui segments">
      <div className="ui segment">
        <div className="ui horizontal buttons">
          <ButtonGroup>
            <Tooltip title={<Typography> "update" </Typography>}>
              <Button> "Refresh" </Button>
            </Tooltip>
            <Tooltip
              title={
                <Typography> "Reset sandbox to initial state" </Typography>
              }>
              <Button> "Reset" </Button>
            </Tooltip>
            <Button> "Load from file" </Button>
            <Button> "Reset" </Button>
          </ButtonGroup>
        </div>
      </div>
      <StateLoader />
      /* <sim-general-controls className="ui segment"></sim-general-controls> */
      <div className="ui segment">
        <div className="ui input">
          <input type_="text" placeholder="Random seed" />
        </div>
        <div className="ui button"> {React.string("Commit Seed")} </div>
      </div>
    </div>
  );
};
