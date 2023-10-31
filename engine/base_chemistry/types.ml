module Acid = struct
  include Type_acid
end

module Molecule = struct
  type t = string [@@deriving show, yojson, ord, eq]
end

module Token = struct
  type t = int * Molecule.t [@@deriving show, yojson, eq]
end

module Graber = struct
  type t = { mol_repr : string; str_repr : string }
  [@@deriving show, yojson, eq]
end

module Place = struct
  type t = {
    mutable token : Token.t option;
    extensions : Acid.extension list;
    index : int;
    graber : Graber.t option;
  }
  [@@deriving show, yojson, eq]
end

module Transition = struct
  type input_arc = { source_place : int; iatype : Acid.input_arc }
  [@@deriving show, yojson, eq]

  let _ignore = ()

  type output_arc = { dest_place : int; oatype : Acid.output_arc }
  [@@deriving show, yojson, eq]

  let _ignore = ()

  type t = {
    mutable launchable : bool;
    id : string;
    input_arcs : input_arc list;
    output_arcs : output_arc list;
    index : int;
  }
  [@@deriving show, yojson, eq]
end

module Petri_net = struct
  type t = {
    mol : Molecule.t;
    transitions : Transition.t array;
    places : Place.t array;
    uid : int; [@equal fun a b -> true]
    mutable launchables_nb : int;
  }
  [@@deriving show, yojson, eq]
end

module Proteine = struct
  type t = Acid.acid list
end
