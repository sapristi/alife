module Molecule = struct
  type t = string
    [@@decco]
  [@@deriving show, yojson, ord]
end

module Token = struct
  type t = int * Molecule.t
  [@@decco]
  [@@deriving show, yojson]
end

module Graber = struct
  type t =
    {
      mol_repr : string;
      str_repr : string;
    }
  [@@decco]
  [@@deriving show, yojson]
end

module Place = struct
  type t =
    {mutable token : Token.t option;
     extensions : Acid_types.extension list;
     index : int;
     graber : Graber.t option;
    }
  [@@decco]
  [@@deriving show, yojson]
end

module Transition = struct
   type input_arc = {
    source_place : int;
    iatype : Acid_types.input_arc;
  }
   [@@decco]
   [@@deriving show, yojson]

   let _ignore = ()

  type output_arc = {
    dest_place : int;
    oatype : Acid_types.output_arc;}
  [@@decco]
  [@@deriving show, yojson]

  let _ignore = ()
  type  t =
    {
      mutable launchable : bool;
      id : string;
      input_arcs :  input_arc list;
      output_arcs : output_arc list;
      index : int;
    }
  [@@decco]
  [@@deriving show, yojson]
end

module Petri_net = struct
  type t =
    {
      mol : Molecule.t;
      transitions : Transition.t array;
      places : Place.t array;
      uid : int;
      mutable launchables_nb:int;
    }
  [@@decco]
  [@@deriving show, yojson]
end
