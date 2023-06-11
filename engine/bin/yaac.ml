open Reactors
open Base_chemistry


type eval_params = {
  n_steps: int;
  initial_state: string;
}
[@@deriving subliner]

let eval {initial_state; n_steps} =

  let sandbox =
  initial_state
  |> Yojson.Safe.from_string
  |> Sandbox.signature_of_yojson
  |> Result.get_ok
  |> Sandbox.of_signature
  in
  for i = 0 to n_steps -1 do
    Bacterie_libs.Bacterie.next_reaction !sandbox
  done

let get_pnet mol =
  let res =
    mol
  |> Molecule.to_proteine
  |> Proteine.to_yojson
  in
  print_endline (Yojson.Safe.to_string res)

type params =
  | Get_pnet of {mol: string}
  (* perform evaluation for given number of steps *)
  | Eval of eval_params
  (* return available reactions *)
  | Reactions
  (* compute a single given reaction *)
  | React
[@@deriving subliner]

let handle = function
  | Get_pnet {mol} -> get_pnet mol
  | Eval params -> (eval params |> ignore)
  | Reactions -> print_endline "todo"
  | React -> print_endline "todo"

[%%subliner.cmds
  eval.params <- handle]
(** Some docs *)
