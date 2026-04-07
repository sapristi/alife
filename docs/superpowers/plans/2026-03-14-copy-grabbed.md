# copy_grabbed Reaction Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `copy_grabbed` place extension and `CopyGrabbed` reaction pool to the OCaml engine, enabling copier molecules that are ~70 chars instead of ~137-331.

**Architecture:** `Copy_grabbed_ext` is a new place extension. A place with this extension stores a mutable `copy_buffer` string. A new `CopyGrabbed` reaction pool (like Transition) fires when the place has a token with cursor not past end: it reads the acid at cursor, appends it to the buffer, and advances the cursor in-place. A new `Copy_done_iarc` input arc type extracts the completed copy buffer when cursor reaches the end. The `copy_grabbed_rate` environment parameter controls the Gillespie rate independently.

**Tech Stack:** OCaml 5.x (ppx_deriving_yojson, alcotest), Python 3 (build_copier.py)

---

## Design Decisions

### Molecule encoding
- `Copy_grabbed_ext`: `ABD` (no parameters, no DDF terminator — like `ABB` for Release_ext)
- `Copy_done_iarc`: `BAE<tid>DDF` (follows standard input arc pattern)

### How copy_grabbed works on a Petri net place
1. Place has `Copy_grabbed_ext` in its extensions list
2. Place gains a `mutable copy_buffer : string` field (initialized to `""`)
3. The `CopyGrabbed` reaction fires when: place has a token AND `Token.get_label token <> ""`
4. On firing: read acid char via `Token.get_label`, advance cursor via `Token.move_mol_forward`, append acid char to `copy_buffer`
5. The token is mutated **in-place** (no pop/push) — this is key: the reaction doesn't consume the token

### How Copy_done_iarc works on a transition
- **Launchability:** place has `Copy_grabbed_ext`, has a token, `Token.get_label token = ""` (cursor past end), AND `copy_buffer <> ""`
- **Firing:** pops the token (the original template), extracts `copy_buffer` as a new token `(0, copy_buffer)`, clears buffer. Produces `[template_token; copy_token]` — exactly like `Copy_iarc` produces `[original; acid_token]`

### Copier molecule design (T-copier)
```
P0: place() ext_grab(pattern) ia_reg(T_LOAD)
P1: place() ext_copy_grabbed() ia_copy_done(T_DONE) oa_reg(T_LOAD)
P2: place() ext_release() oa_reg(T_DONE)
P3: place() ext_release() oa_reg(T_DONE)
```
2 transitions (T_LOAD, T_DONE), 4 places. ~69 chars.

### Rate model
- `copy_grabbed_ready_nb` on the Petri net = count of places with `Copy_grabbed_ext` + token + cursor not past end
- `CopyGrabbed` reaction rate = `copy_grabbed_ready_nb` (same pattern as Transition rate = `launchables_nb`)
- Environment multiplier: `copy_grabbed_rate` (like `transition_rate`)
- Since ambient concentration is constant, rate doesn't depend on which acid is at cursor

### Interaction with transitions
- After a `CopyGrabbed` reaction fires, `update_launchables` runs (cursor advanced may enable/disable `Copy_done_iarc` transitions)
- After `T_LOAD` fires (token enters copy_grabbed place), `update_launchables` runs AND `copy_grabbed_ready_nb` updates — CopyGrabbed reactions become available

---

## Chunk 1: Engine Core Types and Parsing

### Task 1: Add Copy_grabbed_ext and Copy_done_iarc to types

**Files:**
- Modify: `engine/base_chemistry/types.ml`

- [ ] **Step 1: Add `copy_buffer` field to Place.t and new extension/arc types**

In `types.ml`, add to the `extension` type:
```ocaml
  | Copy_grabbed_ext
```

Add to the `input_arc` type:
```ocaml
  | Copy_done_iarc
  (** Fires when cursor past end on a Copy_grabbed place.
      Produces [template_token; copy_buffer_token]. *)
```

Add `copy_buffer` to `Place.t`:
```ocaml
module Place = struct
  type t = {
    mutable token : Token.t option;
    extensions : Acid.extension list;
    index : int;
    graber : Graber.t option;
    mutable copy_buffer : string;
  }
  [@@deriving show, yojson, eq]
end
```

- [ ] **Step 2: Build to check for type errors**

Run: `cd engine && dune build 2>&1 | head -40`
Expected: Compilation errors from exhaustive match statements that don't handle the new variants yet. That's expected — we'll fix those in subsequent tasks.

- [ ] **Step 3: Commit**

```
git add engine/base_chemistry/types.ml
git commit -m "engine: add Copy_grabbed_ext and Copy_done_iarc types"
```

### Task 2: Add molecule parser entries

**Files:**
- Modify: `engine/base_chemistry/molecule.ml`

- [ ] **Step 1: Add acid identifiers and regex patterns**

After `ext_tinit_id = "ABC"`, add:
```ocaml
and ext_copy_grabbed_id = "ABD"
```

After `ia_copy_id = "BAD"`, add:
```ocaml
and ia_copy_done_id = "BAE"
```

After `ext_tinit_re`:
```ocaml
and ext_copy_grabbed_re = ext_copy_grabbed_id
```

After `ia_copy_re`:
```ocaml
and ia_copy_done_re = ia_copy_done_id ^ id_group_re ^ msg_end_id
```

- [ ] **Step 2: Add parser entries to `parsers` list**

After the `ext_tinit_re` parser entry, add:
```ocaml
    ( ext_copy_grabbed_re,
      fun groups ->
        let s' = Re.Group.get groups 1 in
        (Extension Copy_grabbed_ext, s') );
```

After the `ia_copy_re` parser entry, add:
```ocaml
    ( ia_copy_done_re,
      fun groups ->
        let tid = Re.Group.get groups 1 and s' = Re.Group.get groups 2 in
        (InputArc (tid, Copy_done_iarc), s') );
```

- [ ] **Step 3: Add serializer entries to `of_acid`**

Add to `of_acid`:
```ocaml
  | Extension Copy_grabbed_ext -> ext_copy_grabbed_id
```

And:
```ocaml
  | InputArc (s, Copy_done_iarc) -> ia_copy_done_id ^ s ^ msg_end_id
```

- [ ] **Step 4: Build to verify parser compiles**

Run: `cd engine && dune build 2>&1 | head -40`

- [ ] **Step 5: Commit**

```
git add engine/base_chemistry/molecule.ml
git commit -m "engine: add Copy_grabbed_ext and Copy_done_iarc molecule encoding"
```

### Task 3: Update Place module

**Files:**
- Modify: `engine/base_chemistry/place.ml`

- [ ] **Step 1: Initialize copy_buffer in `make`, add helpers**

In `make`, add `copy_buffer = ""` to the record:
```ocaml
  { token; extensions; index; graber; copy_buffer = "" }
```

Add helper functions after `get_possible_mol_grabs`:
```ocaml
let has_copy_grabbed_ext (p : t) : bool =
  List.mem Types.Acid.Copy_grabbed_ext p.extensions

let is_copy_grabbed_ready (p : t) : bool =
  has_copy_grabbed_ext p &&
  match p.token with
  | None -> false
  | Some token -> Token.get_label token <> ""

let execute_copy_grabbed_step (p : t) : unit =
  match p.token with
  | None -> failwith "place.ml: copy_grabbed on empty place"
  | Some token ->
    let acid_char = Token.get_label token in
    p.copy_buffer <- p.copy_buffer ^ acid_char;
    p.token <- Some (Token.move_mol_forward token)

let extract_copy_buffer (p : t) : Token.t =
  let buf = p.copy_buffer in
  p.copy_buffer <- "";
  Token.make_at_mol_start buf
```

- [ ] **Step 2: Build**

Run: `cd engine && dune build 2>&1 | head -40`

- [ ] **Step 3: Commit**

```
git add engine/base_chemistry/place.ml
git commit -m "engine: add copy_grabbed place helpers"
```

### Task 4: Update Transition for Copy_done_iarc

**Files:**
- Modify: `engine/base_chemistry/transition.ml`

- [ ] **Step 1: Add launchability check for Copy_done_iarc**

In `launchable_input_arc`, add a case after `Copy_iarc`:
```ocaml
      | Types.Acid.Copy_done_iarc -> (
          match place.Place.token with
          | None -> false
          | Some token ->
            Token.get_label token = ""
            && Place.has_copy_grabbed_ext place
            && place.Place.copy_buffer <> "")
```

- [ ] **Step 2: Add firing logic for Copy_done_iarc in `apply_input_arcs`**

In `apply_input_arcs`, add a case after `Copy_iarc`:
```ocaml
        | Types.Acid.Copy_done_iarc ->
            let copy_token = Place.extract_copy_buffer place in
            token :: copy_token :: apply_input_arcs i_arc_l'
```

- [ ] **Step 3: Exclude Copy_done_iarc from dedup (it pops, but shares place with no other popping arc in practice — actually it does pop, so dedup is fine as-is)**

No change needed. `Copy_done_iarc` pops the token just like other arcs. It's the only popping arc on its place, so dedup won't filter it.

- [ ] **Step 4: Build**

Run: `cd engine && dune build 2>&1 | head -40`

- [ ] **Step 5: Commit**

```
git add engine/base_chemistry/transition.ml
git commit -m "engine: add Copy_done_iarc launchability and firing logic"
```

### Task 5: Update Petri_net for copy_grabbed_ready_nb

**Files:**
- Modify: `engine/base_chemistry/petri_net.ml`

- [ ] **Step 1: Add copy_grabbed_ready_nb tracking to update_launchables**

Add after `update_launchables`:
```ocaml
let count_copy_grabbed_ready (pnet : t) : int =
  Array.fold_left
    (fun count place ->
      if Place.is_copy_grabbed_ready place then count + 1 else count)
    0 pnet.places
```

Add function to pick and execute a random copy_grabbed step:
```ocaml
let launch_random_copy_grabbed randstate (p : t) : unit =
  let ready =
    CCArray.filter Place.is_copy_grabbed_ready p.places
  in
  if Array.length ready > 0 then
    let place = Random_s.pick_from_array randstate ready in
    Place.execute_copy_grabbed_step place
```

- [ ] **Step 2: Build**

Run: `cd engine && dune build 2>&1 | head -40`

- [ ] **Step 3: Commit**

```
git add engine/base_chemistry/petri_net.ml
git commit -m "engine: add copy_grabbed_ready counting and launching"
```

## Chunk 2: Reaction System Integration

### Task 6: Add copy_grabbed_rate to Environment

**Files:**
- Modify: `engine/bacterie/environment.ml`

- [ ] **Step 1: Add copy_grabbed_rate field**

```ocaml
type t = {
  mutable transition_rate : Q.t;[@default Q.zero]
  mutable grab_rate : Q.t;[@default Q.zero]
  mutable break_rate : Q.t;[@default Q.zero]
  mutable break_length_exponent : float; [@default 0.5]
  mutable collision_rate : Q.t; [@default Q.zero]
  mutable copy_grabbed_rate : Q.t; [@default Q.zero]
}
```

Add to `null_env`:
```ocaml
  copy_grabbed_rate = Q.zero;
```

- [ ] **Step 2: Build**

Run: `cd engine && dune build 2>&1 | head -40`

- [ ] **Step 3: Commit**

```
git add engine/bacterie/environment.ml
git commit -m "engine: add copy_grabbed_rate to environment"
```

### Task 7: Add CopyGrabbed reaction module

**Files:**
- Modify: `engine/bacterie/reactions.ml`

- [ ] **Step 1: Add CopyGrabbed module after Transition**

In `ReactionsM` functor, after the `Transition` module:
```ocaml
  module CopyGrabbed : REAC with type build_t = R.Amol.t = struct
    let name = "CopyGrabbed"
    type t = { mutable rate : Q.t; [@compare fun a b -> 0] amd : R.Amol.t }
    [@@deriving ord, show, to_yojson, eq]

    type build_t = R.Amol.t

    let calculate_rate (cg : t) =
      Q.of_int (Petri_net.count_copy_grabbed_ready cg.amd.pnet)

    let rate (g : t) : Q.t =
      let res = g.rate and calc = calculate_rate g in
      if Q.equal res calc
      then res
      else (
        logger.warning ~tags:["stored", to_yojson g; "computed", Q.to_yojson calc] "Rate error";
        failwith "problem"
      )

    let update_rate ({ rate; _ } as cg : t) =
      let old_rate = rate in
      cg.rate <- calculate_rate cg;
      Q.(cg.rate - old_rate)

    let make (amd : build_t) =
      { rate = calculate_rate { amd; rate = Q.zero }; amd }

    let eval randstate (cg : t) : action list =
      Petri_net.launch_random_copy_grabbed randstate cg.amd.pnet;
      [
        Update_launchables cg.amd;
        Update_reacs (R.Amol.reacs cg.amd);
      ]

    let remove_reac_from_reactants reac g = ()
    let get_reactants cg = cg.amd
  end
```

- [ ] **Step 2: Build**

Run: `cd engine && dune build 2>&1 | head -40`

- [ ] **Step 3: Commit**

```
git add engine/bacterie/reactions.ml
git commit -m "engine: add CopyGrabbed reaction module"
```

### Task 8: Wire CopyGrabbed into Reaction/Reacs/ReacSet

**Files:**
- Modify: `engine/bacterie/reaction.ml`

- [ ] **Step 1: Add CopyGrabbed to Reacs signature and Reaction type**

In the `Reacs` signature (after `module Collision`), add:
```ocaml
  module CopyGrabbed : REAC with type build_t = Reactant.Amol.t
```

In the `Reaction` type, add the variant:
```ocaml
  type t =
    | Grab of Reacs.Grab.t
    | Transition of Reacs.Transition.t
    | Break of Reacs.Break.t
    | Collision of Reacs.Collision.t
    | CopyGrabbed of Reacs.CopyGrabbed.t
```

In `treat_reaction`, add:
```ocaml
    | CopyGrabbed cg -> CopyGrabbed.eval randstate cg
```

In `unlink`, add:
```ocaml
    | CopyGrabbed cg -> CopyGrabbed.remove_reac_from_reactants r cg
```

- [ ] **Step 2: Build**

Run: `cd engine && dune build 2>&1 | head -40`

- [ ] **Step 3: Commit**

```
git add engine/bacterie/reaction.ml
git commit -m "engine: wire CopyGrabbed into Reaction type"
```

### Task 9: Add CopyGrabbed pool to reac_mgr

**Files:**
- Modify: `engine/bacterie/reac_mgr.ml`

- [ ] **Step 1: Add CGSet and wire into reac_mgr**

After `BSet`:
```ocaml
module CGSet = MakeReacSet (Reacs.CopyGrabbed)
```

Add to `type t`:
```ocaml
  cg_set : CGSet.t;
```

Add to `get_available_reac_nb`:
```ocaml
let get_available_reac_nb rmgr =
  (TSet.cardinal rmgr.t_set, GSet.cardinal rmgr.g_set, BSet.cardinal rmgr.b_set, CGSet.cardinal rmgr.cg_set)
```
Note: check if this return type is used elsewhere and update accordingly. If it causes issues, just leave it as-is and add a separate accessor.

Actually, `get_available_reac_nb` returns a tuple that may be pattern-matched. Safest approach: don't change the tuple, but add a new field to `stats`. Let me reconsider — just leave `get_available_reac_nb` as-is (it's only used in a few places).

Add to `stats`:
```ocaml
    "copy_grabbed", make_json_stats (CGSet.stats rmgr.cg_set) !(rmgr.env).copy_grabbed_rate;
```

Add to `to_yojson`:
```ocaml
      ("copy_grabbed", CGSet.to_yojson rmgr.cg_set);
```

Add to `make_new`:
```ocaml
    cg_set = CGSet.empty ();
```

Add to `remove_reactions`, in the match:
```ocaml
      | CopyGrabbed cg -> CGSet.remove cg reac_mgr.cg_set
```

Add `add_copy_grabbed` function:
```ocaml
let add_copy_grabbed amd reac_mgr =
  logger.debug ~tags:["amol", Reactant.Amol.to_yojson amd] "adding new copy_grabbed";
  let cg = Reacs.CopyGrabbed.make amd in
  CGSet.add cg reac_mgr.cg_set;
  let rcg = Reaction.CopyGrabbed cg in
  Reactant.Amol.add_reac rcg amd
```

Update `pick_next_reaction` to include the CopyGrabbed pool:
```ocaml
  let total_cg_rate =
    Q.( !(reac_mgr.env).copy_grabbed_rate * CGSet.total_rate reac_mgr.cg_set )
  in
  let a0 = Q.( total_g_rate + total_t_rate + total_b_rate + total_c_rate + total_cg_rate )
  in
  ...
  (* In the cascading if-else, add before the collision fallback: *)
      else if Q.( lt bound (total_g_rate + total_t_rate + total_b_rate + total_cg_rate) ) then
        Reaction.CopyGrabbed (CGSet.pick_reaction randstate reac_mgr.cg_set)
      else Reaction.Collision (CSet.pick_reaction randstate reac_mgr.c_set)
```

Update `update_reaction_rate`:
```ocaml
  | CopyGrabbed cg -> CGSet.update_rate cg reac_mgr.cg_set
```

Update `check_reac_rates`:
```ocaml
  CGSet.check_reac_rates reac_mrg.cg_set
```

- [ ] **Step 2: Build**

Run: `cd engine && dune build 2>&1 | head -40`

- [ ] **Step 3: Commit**

```
git add engine/bacterie/reac_mgr.ml
git commit -m "engine: add CopyGrabbed pool to reac_mgr"
```

### Task 10: Wire into bacterie.ml

**Files:**
- Modify: `engine/bacterie/bacterie.ml`

- [ ] **Step 1: Add copy_grabbed reaction when adding active molecules**

In `add_active_molecule`, after the transition line, add:
```ocaml
  (* reaction : copy_grabbed *)
  if Petri_net.count_copy_grabbed_ready pnet > 0 ||
     Array.exists Place.has_copy_grabbed_ext pnet.places then
    Reac_mgr.add_copy_grabbed ar bact.reac_mgr;
```

Wait, we should always add it if the pnet has any copy_grabbed places, even if none are ready yet (they become ready after a grab). Simpler:
```ocaml
  (* reaction : copy_grabbed *)
  if Array.exists Place.has_copy_grabbed_ext pnet.places then
    Reac_mgr.add_copy_grabbed ar bact.reac_mgr;
```

- [ ] **Step 2: Fix dummy pnet in AmolSet.find_by_id**

In `reactants_maps.ml`, `AmolSet.find_by_id` creates a dummy pnet. It needs the new `copy_buffer` field on places. But the dummy pnet has `places = [||]` (empty array), so no Place values are constructed. No change needed.

However, check that `Petri_net.t` type in `types.ml` doesn't have new required fields. It doesn't — we're not adding fields to `Petri_net.t`, just to `Place.t`. And `Place.make` initializes `copy_buffer`. So we're fine.

- [ ] **Step 3: Build**

Run: `cd engine && dune build 2>&1 | head -40`

- [ ] **Step 4: Commit**

```
git add engine/bacterie/bacterie.ml
git commit -m "engine: wire copy_grabbed into bacterie molecule addition"
```

## Chunk 3: Tests and Python Builder

### Task 11: Create test fixture and test

**Files:**
- Create: `engine/tests/bact_states/copy_grabbed_copier.json`
- Create: `engine/tests/test_copy_grabbed.ml`
- Modify: `engine/tests/initial_states.ml`
- Modify: `engine/tests/tests.ml`

- [ ] **Step 1: Create test fixture JSON**

The copier molecule encodes as:
```
P0: AAA ABAFDFAFFDDF BAAADDF
P1: AAA ABD BAEBDDF CAAADDF
P2: AAA ABB CAABDDF
P3: AAA ABB CAABDDF
```

Concatenated: `AAAABAFDFAFFDDFBAAADDFAAAABDBAEBDDFCAAADDFAAAABBCAABDDFAAAABBCAABDDF`

The template is DAEEE + copier_mol.

Write `engine/tests/bact_states/copy_grabbed_copier.json`:
```json
{
  "mols": [
    {
      "mol": "<copier_mol>",
      "qtt": 5
    },
    {
      "mol": "DAEEE<copier_mol>",
      "qtt": 10
    },
    {"mol": "A", "qtt": 200, "ambient": true},
    {"mol": "B", "qtt": 200, "ambient": true},
    {"mol": "C", "qtt": 200, "ambient": true},
    {"mol": "D", "qtt": 50, "ambient": true},
    {"mol": "E", "qtt": 200, "ambient": true},
    {"mol": "F", "qtt": 200, "ambient": true}
  ],
  "env": {
    "transition_rate": 100,
    "grab_rate": 1,
    "break_rate": 0,
    "collision_rate": 0,
    "copy_grabbed_rate": 100
  }
}
```

**Important:** The actual molecule string must be computed. Use the Python builder (Task 12) to generate it, then paste back. For now, use a placeholder and update after Task 12.

- [ ] **Step 2: Add to initial_states.ml**

```ocaml
let copy_grabbed_copier () = load "copy_grabbed_copier"
```

Add `"copy_grabbed_copier"` to the `names` list.

- [ ] **Step 3: Create test_copy_grabbed.ml**

```ocaml
open Bacterie_libs
open Reactants_maps

let count_areactants bact =
  let json = ARMap.stats bact.Bacterie.areactants in
  match json with
  | `Assoc l ->
    (match List.assoc "total_nb" l with `Int n -> n | _ -> 0)
  | _ -> 0

let count_ireactants bact =
  let json = IRMap.stats bact.Bacterie.ireactants in
  match json with
  | `Assoc l ->
    (match List.assoc "total_nb" l with `Int n -> n | _ -> 0)
  | _ -> 0

let run_reactions n bact =
  for _ = 1 to n do
    ignore (Bacterie.next_reaction bact);
    Reac_mgr.check_reac_rates bact.reac_mgr
  done

let test_copy_grabbed_replicates () =
  (* GIVEN a copy_grabbed copier system *)
  let bact = Initial_states.copy_grabbed_copier () in
  let initial_active = count_areactants bact in

  (* WHEN we run 2000 reactions *)
  run_reactions 2000 bact;

  (* THEN active molecules should have increased (copies were made) *)
  let final_active = count_areactants bact in
  Alcotest.(check bool)
    (Printf.sprintf
       "active molecules should increase (initial=%d, final=%d)"
       initial_active final_active)
    true (final_active > initial_active)

let test_copy_grabbed_produces_templates () =
  (* GIVEN a copy_grabbed copier system *)
  let bact = Initial_states.copy_grabbed_copier () in
  let initial_inert = count_ireactants bact in

  (* WHEN we run 5000 reactions *)
  run_reactions 5000 bact;

  (* THEN inert molecules (templates) should have increased *)
  let final_inert = count_ireactants bact in
  Alcotest.(check bool)
    (Printf.sprintf
       "inert molecule count should increase (initial=%d, final=%d)"
       initial_inert final_inert)
    true (final_inert > initial_inert)
```

- [ ] **Step 4: Add test cases to tests.ml**

```ocaml
      ( "CopyGrabbed replication",
        [
          test_case "copy_grabbed replicates" `Slow
            Test_copy_grabbed.test_copy_grabbed_replicates;
          test_case "copy_grabbed produces templates" `Slow
            Test_copy_grabbed.test_copy_grabbed_produces_templates;
        ]
      );
```

- [ ] **Step 5: Build and run tests**

Run: `cd engine && dune build && dune runtest 2>&1 | tail -20`

- [ ] **Step 6: Commit**

```
git add engine/tests/
git commit -m "engine: add copy_grabbed replication tests"
```

### Task 12: Add Python builder functions

**Files:**
- Modify: `django/build_copier.py`

- [ ] **Step 1: Add encoding functions and builder**

After `ext_init_token()`:
```python
def ext_copy_grabbed(): return "ABD"
def ia_copy_done(tid): return f"BAE{tid}DDF"
```

Add new builder function:
```python
def build_copy_grabbed_copier(grab_pattern="FDFAFF"):
    """Build copier using copy_grabbed extension.

    The copy_grabbed place atomically reads acid at cursor, appends to
    internal buffer, and advances cursor. One CopyGrabbed reaction per
    acid copied. Copy_done_iarc extracts the buffer when cursor past end.

    Transitions: T_LOAD, T_DONE (2 total)
    Places: P0(grab), P1(copy_grabbed read head), P2(copy release),
            P3(template release) (4 total)
    """
    T_LOAD = "A"
    T_DONE = "B"

    parts = []

    # P0: Template grab
    parts.append(place())
    parts.append(ext_grab(grab_pattern))
    parts.append(ia_reg(T_LOAD))

    # P1: Copy_grabbed read head
    # Arc ordering: ia_copy_done produces [template, copy]
    # After proteine.ml prepend, output arcs are [(P3, reg), (P2, reg)]
    # So P3 gets template, P2 gets copy
    parts.append(place())
    parts.append(ext_copy_grabbed())
    parts.append(ia_copy_done(T_DONE))
    parts.append(oa_reg(T_LOAD))

    # P2: Copy release
    parts.append(place())
    parts.append(ext_release())
    parts.append(oa_reg(T_DONE))

    # P3: Template release
    parts.append(place())
    parts.append(ext_release())
    parts.append(oa_reg(T_DONE))

    return "".join(parts)
```

Add initial state builder:
```python
def build_copy_grabbed_initial_state(copier_mol, grab_pattern="FDFAFF",
                                     copier_qtt=5, template_qtt=10,
                                     acid_qtt=200, d_qtt=50, e_qtt=200):
    """Build initial state for copy_grabbed copier system."""
    template = TEMPLATE_PREFIX + copier_mol

    return {
        "mols": [
            {"mol": copier_mol, "qtt": copier_qtt},
            {"mol": template, "qtt": template_qtt},
            {"mol": "A", "qtt": acid_qtt, "ambient": True},
            {"mol": "B", "qtt": acid_qtt, "ambient": True},
            {"mol": "C", "qtt": acid_qtt, "ambient": True},
            {"mol": "D", "qtt": d_qtt, "ambient": True},
            {"mol": "E", "qtt": e_qtt, "ambient": True},
            {"mol": "F", "qtt": acid_qtt, "ambient": True},
        ],
        "env": {
            "transition_rate": 100,
            "grab_rate": 1,
            "break_rate": 0,
            "collision_rate": 0,
            "copy_grabbed_rate": 100,
        }
    }
```

Add CLI support in `__main__`:
```python
    parser.add_argument("--copy-grabbed", action="store_true",
                        help="Build copy_grabbed copier")
```

And the handler:
```python
    elif args.copy_grabbed:
        copier = build_copy_grabbed_copier()
        template = TEMPLATE_PREFIX + copier

        print("Copy_grabbed copier:")
        verify_molecule(copier, "Copier")
        verify_molecule(template, "Template")
        print()

        state = build_copy_grabbed_initial_state(copier)
        print(f"Initial state: {len(state['mols'])} mol types, "
              f"{sum(m['qtt'] for m in state['mols'])} total")
        print(json.dumps(state, indent=2))
```

- [ ] **Step 2: Generate the molecule and update test fixture**

Run: `cd django && python build_copier.py --copy-grabbed`

Copy the generated JSON into `engine/tests/bact_states/copy_grabbed_copier.json`.

- [ ] **Step 3: Run full test suite**

Run: `cd engine && dune runtest 2>&1`

- [ ] **Step 4: Commit**

```
git add django/build_copier.py engine/tests/bact_states/copy_grabbed_copier.json
git commit -m "engine: add copy_grabbed copier builder and test fixture"
```

### Task 13: Update README acid table

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add new acid types to the table**

Add to the acid types table:
```
| `ABD` | — | Copy_grabbed_ext | Place with internal copy buffer for copy_grabbed reaction |
| `BAE` | `<id>DDF` | Copy_done_iarc | Fires when copy_grabbed buffer complete; produces [template, copy] |
```

- [ ] **Step 2: Commit**

```
git add README.md
git commit -m "docs: add Copy_grabbed_ext and Copy_done_iarc to acid table"
```

### Task 14: Update CLAUDE.md with copy_grabbed design notes

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add copy_grabbed design notes**

Add to the "Copier design notes" section:
```
## Copy_grabbed design notes
- **Copy_grabbed_ext** place extension: stores mutable `copy_buffer`, incremented by CopyGrabbed reactions
- **CopyGrabbed reaction**: reads acid at cursor, appends to buffer, advances cursor in-place (no token pop/push)
- **Copy_done_iarc**: fires when cursor past end + buffer non-empty, produces [template, copy_buffer] tokens
- **Rate**: `copy_grabbed_ready_nb` (count of places with ext + token + cursor not past end) * `copy_grabbed_rate`
- Builders: `build_copy_grabbed_copier()` in `django/build_copier.py`
```

- [ ] **Step 2: Commit**

```
git add CLAUDE.md
git commit -m "docs: add copy_grabbed design notes to CLAUDE.md"
```
