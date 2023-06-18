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

let build_all_from_mol mol =
    let prot_json = mol
                    |> Molecule.to_proteine
                    |> Proteine.to_yojson
    in
    let pnet_json =
      match Petri_net.make_from_mol mol with
      | Some pnet -> Petri_net.to_yojson pnet
      | None -> `Null
    in
  (
        `Assoc
          [ "prot", prot_json;
            "pnet", pnet_json]
  )
  |> Yojson.Safe.to_string
|> Result.ok

let build_all_from_prot (prot_str: string) =
  match
    prot_str
    |> Yojson.Safe.from_string
    |> Proteine.of_yojson
  with
  | Ok prot ->
    (
      let mol = Molecule.of_proteine prot in
      let mol_json = `String mol in
      let pnet_json =
        match Petri_net.make_from_mol mol with
        | Some pnet -> Petri_net.to_yojson pnet
        | None -> `Null
      in
     (`Assoc
               ["mol", mol_json;
                "pnet", pnet_json])
  |> Yojson.Safe.to_string
  |> Result.ok
    )
  | Error s -> Error s


type params =

  | From_mol of {mol: string}
  | From_prot of {prot: string}
  (* perform evaluation for given number of steps *)
  | Eval of eval_params
  (* return available reactions *)
  | Reactions
  (* compute a single given reaction *)
  | React
[@@deriving subliner]

let handle = function
| From_mol {mol} -> build_all_from_mol mol
| From_prot {prot} -> build_all_from_prot prot
  | Eval params -> (eval params |> ignore); Ok "todo"
  | Reactions -> Ok "todo"
  | React -> Ok "todo"

let handle_wrapped input =
match
 handle input
with
| Ok result -> print_endline result
| Error err -> prerr_endline err; exit 1

[%%subliner.cmds
  eval.params <- handle_wrapped]
(** Some docs *)
