module Molecule = struct
  type t = string
  [@@deriving show, yojson, ord]
end

module Token = struct
  type t = int * Molecule.t
  [@@deriving show, yojson]
end

