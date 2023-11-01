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

module Download = {
  [@react.component] [@bs.module "react-feather"]
    external make: (~color: string=?, ~size: int=?) => React.element = "Download";
};


module Upload = {
  [@react.component] [@bs.module "react-feather"]
    external make: (~color: string=?, ~size: int=?) => React.element = "Upload";
};

module Pocket = {
  [@react.component] [@bs.module "react-feather"]
    external make: (~color: string=?, ~size: int=?) => React.element = "Pocket";
};

module Save = {
  [@react.component] [@bs.module "react-feather"]
    external make: (~color: string=?, ~size: int=?) => React.element = "Save";
};


module type ICON = (module type of {include Pause});
