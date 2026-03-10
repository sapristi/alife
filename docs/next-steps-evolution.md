# Next Steps: Enabling Darwinian Evolution in YAACS

**Date:** 2026-03-08
**Context:** Copier v4 (inert templates) achieves self-replication and molecular diversification, but NOT Darwinian evolution. This document outlines what's missing and the proposed path forward.

> **Status (2026-03-10):** Copier v5 (Copy_iarc) resolved the heritable variation gap. Darwinian evolution confirmed in exp 71 (3 Darwinian pairs at 400k). The `copy_grabbed` extension is now a nice-to-have for fitness landscape smoothing, no longer critical. See `docs/experiments.md` for full results.

## Current State

- **Copier v4** (experiments 55-58): first full self-replicating system
- Best result (exp 57, grab=5, mutations): 72 active species from 2 originals in 200k reactions
- System shows open-ended diversification but no heritable variation
- Grab=5 is optimal; grab=10 kills the system (~49k); grab=1 is slower but stable

## What's Missing for Darwinian Evolution

### 1. Heritable variation (critical gap)

Mutations happen to **copiers** (phenotype) but copiers replicate via **templates** (genotype). A mutant copier has no corresponding template, so it can't reproduce. The genotype-phenotype split means mutations aren't inherited.

Two pathways could fix this:

- **Template-level mutations** (partially possible): if a template breaks inside the body (position >5), the `DAEEE + partial_body` fragment is still a valid grabbable template. R-copier would produce a truncated copier variant. But odds of producing a *functional* truncated copier are very low given copier complexity (400-600 chars).

- **Template creation from mutant copiers** (missing entirely): no mechanism to prepend DAEEE to a mutant copier. Collision could theoretically do it (DAEEE fragment + mutant copier), but requires break at exactly position 5 then collision in right order — astronomically unlikely.

### 2. Mutations rarely produce functional molecules

The T-copier is 401 chars of precisely structured Petri net. A break at almost any position destroys critical functionality. The fitness landscape is a **sharp spike** — all neighbors are dead.

### 3. No differential fitness among replicators

All copiers use the same grab pattern (`^(D)A.*?$`) and compete for the same template pool. No way for a mutant copier to be better at replicating.

## Proposed Solution: `copy_grabbed` Engine Extension

### Why modular degradation doesn't work

We explored adding skip transitions (guarded by `ia_no_token` on acid grab places) so copiers missing a module skip that acid instead of getting stuck.

**Problem:** when a module's place (P_X) is broken off, its input arc is also removed from the copy transition. The transition fires with fewer tokens than expected, but the merge output still needs the full token count. The engine hits `| _ -> []`, the accumulator token is consumed but not returned, and the entire copy is destroyed.

This is fundamental: removing an arc from a molecule removes a *constraint* on the transition, making it fire with insufficient tokens. There's no way around this in the current Petri net model.

### The real fix: make viable copiers smaller

Add a new place extension `copy_grabbed` that atomically performs: read acid at cursor → grab matching acid from ambient → merge into accumulator → advance cursor. One transition step per acid copied.

A copier becomes ~50-80 chars instead of 400-600:

```
P0: ext_grab(pattern)         -- grab template
P1: ext_copy_grabbed()        -- copy loop, one acid per step
P2: ext_release()             -- release copy
P3: ext_release()             -- release template
P4: ext_init_token()          -- token factory
+ 3 transitions: T_LOAD, T_DONE, T_RESET
```

### Why this enables evolution

1. **Smooth fitness landscape**: break products from a 50-char copier have a much higher chance of retaining functionality than break products from a 400-char copier.

2. **Smaller templates**: DAEEE + 50 chars = 55 chars instead of 605. Template-level mutations (breaks) more likely to produce functional variants.

3. **Heritable variation becomes likely**: template breaks produce truncated but potentially functional copier variants. With templates only 55 chars, a break at position 30 yields a 30-char template that R-copier reads to produce a 25-char copier — which might still have a grab + copy + release loop.

4. **Template creation via collision becomes feasible**: shorter molecules mean DAEEE fragments colliding with short copiers produce valid templates more often. Could also add ambient DAEEE molecules to increase the rate.

### Implementation scope

Engine changes needed:

- `engine/base_chemistry/molecule.ml` — new acid type `ext_copy_grabbed_id` + parser entry
- `engine/base_chemistry/transition.ml` or `place.ml` — copy logic (read cursor acid, grab matching ambient, merge into accumulator, advance cursor)
- Semantics: one acid copied per transition step (fits Gillespie framework)

Python changes:

- `django/build_copier.py` — simplified copier builder using new extension
- New initial state with small copiers + small templates

### Open questions

- Should `copy_grabbed` handle the full read-grab-merge-advance in one transition firing, or break it into sub-steps?
- Does the copy extension need to handle end-of-molecule detection, or should that remain a separate `filter_empty` arc?
- Should the extension skip unrecognized acids (enabling imperfect copying of mutants) or fail?

## Alternative/Complementary Approaches

These could be combined with the engine extension:

- **Ambient DAEEE molecules**: add DAEEE as ambient; collisions naturally create templates from active molecules. Simple, no code changes, but probabilistic.
- **Template maker molecule**: a new molecule that grabs active molecules and prepends DAEEE. Systematic but complex to build with current Petri nets (trivial with `copy_grabbed`).
- **Variable grab patterns**: mutations to the grab pattern region create copiers with different template affinities → niche differentiation → selection pressure.
