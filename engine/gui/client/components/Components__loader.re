module Animate = {
  [@react.component]
  let make = (~transformValues, ~animateValues) => {
    <React.Fragment>
      <animateTransform
        attributeName="transform"
        type_="rotate"
        dur="1s"
        repeatCount="indefinite"
        keyTimes="0;1"
        values=transformValues
      />
      <animate
        attributeName="r"
        dur="1s"
        repeatCount="indefinite"
        calcMode="spline"
        keyTimes="0;0.5;1"
        values=animateValues
        keySplines="0.2 0 0.8 1;0.2 0 0.8 1"
      />
    </React.Fragment>;
  };
};

module LoaderRunning = {
  [@react.component]
  let make = () => {
    <svg
      xmlns="http://www.w3.org/2000/svg"
      style=Css.(style([margin(auto), display(block)]))
      width="50px"
      height="50px"
      viewBox="0 0 100 100"
      preserveAspectRatio="xMidYMid">
      <g transform="translate(0 -18)">
        <circle cx="50" cy="28.400000000000002" r="10" fill="#93dbe9">
          <Animate
            transformValues="0 50 50;360 50 50"
            animateValues="0;36;0"
          />
        </circle>
        <circle cx="50" cy="28.400000000000002" r="10" fill="#689cc5">
          <Animate
            transformValues="180 50 50;540 50 50"
            animateValues="36;0;36"
          />
        </circle>
      </g>
    </svg>;
  };
};

module LoaderPaused = {
  [@react.component]
  let make = () => {
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="50px"
      height="50px"
      viewBox="0 0 100 100"
      preserveAspectRatio="xMidYMid"
      style=Css.(style([margin(auto), display(block)]))>
      <g transform="translate(0 -18)">
        <circle
          cx="50"
          cy="28.400000000000002"
          r="36"
          fill="#689cc5"
          transform="matrix(-1,0,0,-1,100,100)"
        />
      </g>
    </svg>;
  };
};

[@react.component]
let make = (~active) =>
  if (active) {
    <LoaderRunning />;
  } else {
    <LoaderPaused />;
  };
