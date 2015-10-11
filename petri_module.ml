

module type ID_CLASS =
sig
  type t
  val id : t -> int
end;;

