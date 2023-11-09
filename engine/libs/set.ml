(** Set with an equal operator using the item's equal operator, instead of compare operator
    This is because the equal operator is custom made for tests
*)

module type SetInputSIG = sig
  include Stdlib.Set.OrderedType

  val equal : t -> t -> bool
  val show : t -> string
  val to_yojson : t -> Yojson.Safe.t
end

module Make (O: SetInputSIG) = struct
  include CCSet.Make(O)

  let equal set1 set2 =
    let zipped = Base.List.zip_exn (set1 |> to_list) (set2 |> to_list) in
    Base.With_return.with_return (fun r ->
        List.iter (fun (item1, item2) -> if not (O.equal item1 item2)
                    then
                      (
                        (* logger.warning "Not equal %s %s" (O.show item1) (O.show item2); *)
                        (* flush stdout; *)
                        r.return false
                      )
                  ) zipped;
        true)

  let to_yojson set : Yojson.Safe.t = `List (set |> to_list |> List.map O.to_yojson)
end
