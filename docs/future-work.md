# Future Work

Ideas, remarks, and open questions to address in future development.

## Copying mechanism: from Copy_iarc to copy_grabbed

### Current state: Copy_iarc

Copy_iarc is an input arc type that reads the acid at cursor and materializes a new single-acid token from nothing (`Token.make acid_char 1`). It enables Copier v5, which achieved Darwinian evolution (exp 71). But it has two problems:

1. **Physical incoherence:** creates matter without consuming any resource.
2. **Large copiers:** the full copy loop (grab acid, merge into accumulator, advance cursor) requires many transitions, yielding copiers of ~137-331 chars with a sharp fitness landscape.

### Proposed: copy_grabbed extension

A place extension that atomically performs in one transition firing: read acid at cursor → grab matching acid from ambient → merge into accumulator → advance cursor. Shrinks copiers from ~137-331 to ~50-80 chars, flattening the fitness landscape.

See `docs/next-steps-evolution.md` for full design and rationale.

### Ambient-consumption semantics (applies to both)

Whether Copy_iarc or copy_grabbed, the copy step should consume an atom from the ambient pool. The transition's firing rate should depend on the concentration of the target atom in the environment.

**Point mutations as emergent consequence:** drawing from the ambient pool weighted by concentration means a copier needing a rare atom will sometimes grab a different, more abundant atom instead. Mutation rate becomes an emergent property of environmental chemistry rather than a separate parameter.

### Feasibility: reaction rates for copy_grabbed

The core challenge is that `copy_grabbed` is a **transition-level** reaction whose rate depends on **environment state** (ambient atom concentrations). Currently, transition rates are purely local — `calculate_rate` returns `launchables_nb`, counting how many transitions can fire based only on Petri net token state. copy_grabbed would need a rate that also depends on what atom the cursor points at and how much of that atom is available.

**What makes it tractable:**

1. **Rate computation is already heterogeneous.** Grabs already depend on environment state (`grab_factor * qtt`). The Gillespie loop in `reac_mgr.ml` sums four independent rate pools (transition, grab, break, collision), each with its own `calculate_rate`. Adding a fifth pool (copy_grabbed reactions) or making transition rates environment-aware are both architecturally straightforward.

2. **The cursor acid is known at rate-computation time.** When `update_launchables` runs, we can read the token label at the Copy_iarc/copy_grabbed place to know which acid is needed. This is exactly what the launchability check already does (`Token.get_label token <> ""`).

3. **Ambient quantities are already tracked.** Each `ImolSet` has a `qtt` field. The engine would need a lookup from acid character → ambient quantity, which doesn't exist today but is easy to build (a small hashtable or array indexed by acid char, maintained by `reac_mgr`).

**Proposed rate model:**

```
rate(copy_grabbed transition T in molecule M) = ambient_qtt(acid_at_cursor(M))
```

Where `acid_at_cursor(M)` reads the label of the token in the copy_grabbed place. If the cursor points to "A" and there are 500 ambient "A" atoms, the rate is 500. This is analogous to how grab rates work: `grab_factor * qtt`.

For emergent point mutations (wrong atom grabbed), the rate becomes the **total** ambient atom quantity, with the specific atom chosen stochastically at firing time weighted by relative concentrations. This doesn't change the Gillespie propensity calculation — only the `eval` step.

**Implementation steps:**

1. **Acid concentration index** — Add to `reac_mgr` (or environment) a `char -> int` map tracking total ambient quantity per acid character. Update it when ambient molecules are added/removed. Small change, no architectural impact.

2. **New reaction type or extended transition rate** — Two options:
   - **(a) New reaction pool** `CopyGrabbed` alongside Grab/Transition/Break/Collision: cleanest separation, rate = `ambient_qtt(target_acid)`. Requires a new module in `reactions.ml` and a new set in `reac_mgr.ml`.
   - **(b) Make transition rates environment-aware**: modify `calculate_rate` for Transition to sum per-transition rates instead of just counting launchables. More invasive but avoids a new reaction pool.
   - **Recommendation: option (a)** — follows existing patterns, doesn't touch transition infrastructure.

3. **Firing logic (`eval`)** — On firing: read cursor acid, draw from ambient pool (decrement if not infinite), produce token, merge into accumulator, advance cursor. The multi-step atomic operation is the most complex part but is self-contained in a single `eval` function.

4. **Rate updates** — When a copy_grabbed transition fires, the cursor advances to the next acid. The rate must be recomputed (new acid → different ambient concentration). This happens naturally via `Update_reacs` actions already emitted after transition firing.

**Verdict: feasible, moderate effort.** The Gillespie framework already supports heterogeneous rate pools. The main new infrastructure is the acid concentration index (~30 lines) and a new reaction module (~100 lines following the Grab module pattern). The atomic copy_grabbed operation itself is the bulk of the work but is orthogonal to the rate question.

### Open questions

- Should the copy rate scale with target atom concentration directly, or use a Michaelis-Menten-like saturation model?
- Should a failed copy (wrong atom grabbed) be deterministic (most abundant substitute) or stochastic (weighted by all concentrations)?
- How does this interact with the current ambient `add_to_qtt` no-op? Ambient atoms don't deplete — should copying consume them, or should ambient remain infinite?
- Should copy_grabbed handle end-of-molecule detection, or should that remain a separate `filter_empty` arc?
- Should the extension skip unrecognized acids (enabling imperfect copying of mutants) or fail?

## Membranes

A membrane establishes a barrier with the outside world. Desired properties:

- Regulate molecule entry/exit
- Difficult barrier for unwanted external molecules
- Size requirements proportional to internal molecule count (overfill → damage)

**Implementation idea:** two anchor points connected by a chain of proteins via Bind extensions. Bind extension pairs (symmetric strings) link two Petri nets; binding creates tokens in both places, unbinding when both receive tokens again.

### Bind extension design choices

- Strong bind: Petri nets fuse at bind place (complex state management)
- Weak bind: Petri nets remain independent (simpler, sufficient for membranes)
- Either way, need a supergraph tracking the extended Petri net structure (distances, cycles)

## Energy model

Tokens could mediate energy exchanges. Forming a bond costs energy, breaking it releases energy — mirroring real chemistry. This implies modifying grab/bind conditions to account for energy availability. Could also enable energy transfer between a protein and a grabbed molecule.

## World / spatial structure

Ideas for scaling beyond a single reactor:

- Unrestricted duplication: each new bacterium gets a resource distribution
- 3D matrix with commands for neighbor interaction, movement, communication
- Hosts for multicellular behavior: host has receptor slots, cells plug in to act in a physical world
- Lazy graph where nodes contain membrane interfaces of varying permeability

## Variable grab patterns

Mutations to the grab pattern region could create copiers with different template affinities → niche differentiation → selection pressure.

## Ambient DAEEE molecules

Add DAEEE as ambient; collisions naturally create templates from active molecules. Simple, no code changes, but probabilistic.
