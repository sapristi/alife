module Acid = struct

  type input_arc =
    | Regular_iarc
    | Split_iarc
    (** Cuts molecule in two *)
    | Filter_iarc of string
    (** Only lets through if mol in token matches pattern *)
    | Filter_empty_iarc
    (** Only lets through if mol in token is empty *)
    | No_token_iarc
    (** Only lets through if no token *)
  [@@deriving show, yojson, eq]


  type output_arc =
    | Regular_oarc
    | Merge_oarc
       (** Merge molecules of incoming arcs *)
    | Move_oarc of bool
    (** Displace cursor of molecule in token *)
  [@@deriving show, yojson, eq]


  type extension =
    | Grab_ext of string
    | Release_ext
    | Init_with_token_ext
  [@@deriving show, yojson, eq]

  (* ** type definitions *)
  (* *** acid type definition *)
  (*     We define how the abstract types get combined to form functional *)
  (*     types to eventually create petri net *)
  (*       + Node : used as a token placeholder in the petri net *)
  (*       + TransitionInput :  an incomming edge into a transition of the *)
  (*       petri net *)
  (*       + a transition output : an outgoing edge into a transition of the *)
  (*       petri net *)
  (*       + a piece of information : ???? *)

  type acid =
    | Place
    | InputArc of string * input_arc
    | OutputArc of string * output_arc
    | Extension of extension
  [@@deriving show, yojson, eq]

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

