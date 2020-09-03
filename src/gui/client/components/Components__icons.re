module ChevronRight = {
  [@react.component] [@bs.module "react-feather"]
  external make: (~color: string=?, ~size: int=?) => React.element =
    "ChevronRight";
};
module ChevronLeft = {
  [@react.component] [@bs.module "react-feather"]
  external make: (~color: string=?, ~size: int=?) => React.element =
    "ChevronLeft";
};
module ChevronUp = {
  [@react.component] [@bs.module "react-feather"]
  external make: (~color: string=?, ~size: int=?) => React.element =
    "ChevronUp";
};
module ChevronDown = {
  [@react.component] [@bs.module "react-feather"]
  external make: (~color: string=?, ~size: int=?) => React.element =
    "ChevronDown";
};

module Edit = {
  [@react.component] [@bs.module "react-feather"]
  external make: (~color: string=?, ~size: int=?) => React.element = "Edit2";
};
module Delete = {
  [@react.component] [@bs.module "react-feather"]
  external make: (~color: string=?, ~size: int=?) => React.element = "X";
};

module Play = {
  [@react.component] [@bs.module "react-feather"]
  external make: (~color: string=?, ~size: int=?) => React.element = "Play";
};
module Pause = {
  [@react.component] [@bs.module "react-feather"]
  external make: (~color: string=?, ~size: int=?) => React.element = "Pause";
};
