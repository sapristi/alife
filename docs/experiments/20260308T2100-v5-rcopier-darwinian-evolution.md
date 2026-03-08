# V5 R-copier and Darwinian Evolution Experiments

Date: 2026-03-08

## Context

The v5 T-copier (137 chars, Copy_iarc-based) was already working and producing
exact template copies. The missing piece was an R-copier that reads templates,
skips the DAEEE prefix, and produces active copiers — enabling a full 4-component
self-replicating system where mutations could propagate from templates to copiers.

### 4-component system design

| Component | Length | Role |
|-----------|--------|------|
| T-copier | 137 | Grabs DA-templates, copies exactly (including DAEEE) |
| R-copier | 331 | Grabs DA-templates, skips DAEEE, copies body → active copier |
| Template_T | 142 | DAEEE + T-copier (inert, EEE = stop interpretation) |
| Template_R | 336 | DAEEE + R-copier (inert) |

Builder: `django/build_copier.py` — `build_simple_r_copier()` and `build_simple_4comp_state()`.

## Step 1: R-copier design and debugging

### What we did

Built `build_simple_r_copier()` — a 331-char molecule with 12 places and 9
transitions. It uses Copy_iarc (reads acid at cursor, produces [original,
acid_token]) for both the skip phase (advancing past DAEEE) and the copy phase.

The skip phase uses a 5-step trigger chain: T_SKIP1 through T_SKIP5 fire
sequentially, each advancing the read cursor past one prefix character. After
all 5 skips, T_RESET fills the accumulator and the copy loop begins.

### The race condition problem

In the Gillespie simulation, only one transition fires per step, selected
randomly weighted by rates. After T_SKIP2 consumed the trigger from P2,
T_SKIP1's output arc check passed (P2 empty) and it could fire again —
racing with T_SKIP3/T_SKIP4/etc. This caused duplicate trigger chain entries
and corrupted copies.

### The fix: one-shot gate

Added a gate place (P9) with `ext_init_token`. T_SKIP1 consumes the gate token
via `ia_reg(T_SKIP1)`. After one firing, the gate is empty and T_SKIP1 is
permanently blocked for this cycle. The gate is refilled by T_DONE via factory
split when the copy cycle completes.

Verified with step-by-step trace: `launch=1` at every step — only ONE transition
is launchable at each point, making races impossible.

## Step 2: Clean replication test (Experiment 69)

### Parameters

- Initial: 5 T-copiers, 5 R-copiers, 10 Template_T, 10 Template_R
- Env: transition_rate=100, grab_rate=1, break=0, collision=0
- Duration: 50k reactions

### Expected

Both copier types should replicate through the template system. All copies
should be exact matches (no mutations since break=0).

### Results

| Reactions | T-copiers | R-copiers | Template_T | Template_R |
|-----------|-----------|-----------|------------|------------|
| 0 | 5 | 5 | 10 | 10 |
| 10,000 | 14 | 10 | 2 | 1 |
| 20,000 | 28 | 15 | 0 | 0 |
| 30,000 | 44 | 18 | 2 | 2 |
| 40,000 | 61 | 19 | 4 | 0 |
| 50,000 | 68 | 20 | 7 | 3 |

Zero non-matching molecules. All copies are exact. Both copier types grow
steadily. Templates fluctuate as they're grabbed then released. T-copiers grow
faster because Template_T (142 chars) is shorter than Template_R (336 chars),
so copy cycles complete faster.

### Conclusion

The 4-component self-replicating system works correctly. First v5 full
self-replicator confirmed.

## Step 3: Low mutation rate (Experiment 70)

### Parameters

- Same initial state as exp 69
- Env: transition_rate=100, grab_rate=5, break_rate=1e-6, collision_rate=1e-5
- Duration: 200k reactions

### Expected

With very low break rate, the system should replicate normally with occasional
mutations. Some mutant species should appear but DAEEE-prefixed mutant templates
(needed for the Darwinian pathway) may be too rare.

### Results

| Reactions | T-cop | R-cop | TmplT | TmplR | Mutant inert | Mutant active |
|-----------|-------|-------|-------|-------|--------------|---------------|
| 0 | 5 | 5 | 10 | 10 | 0 (0sp) | 0 (0sp) |
| 50,000 | 47 | 22 | 10 | 4 | 4 (3sp) | 7 (7sp) |
| 100,000 | 99 | 35 | 56 | 8 | 8 (6sp) | 10 (10sp) |
| 200,000 | 198 | 42 | 208 | 24 | 21 (16sp) | 22 (21sp) |

DAEEE-prefixed mutant templates: **0**. The break rate was too low — with
~200 templates of length ~140, breaks happen roughly once per 500k reactions
at this rate.

### Conclusion

System replicates well with mutations creating 37 species by 200k. But no
DAEEE mutant templates appeared, so the Darwinian pathway (template → copier
conversion of mutants) was not exercised. Need higher break rate.

## Step 4: Higher mutation rate (Experiment 71)

### Parameters

- Same initial state
- Env: transition_rate=100, grab_rate=5, break_rate=1e-4, collision_rate=1e-5
- Duration: 400k reactions (target was 500k+, interrupted by snapshot collision)

### Expected

With 100x higher break rate, template breaks should produce DAEEE-prefixed
mutant templates. T-copiers should replicate these mutant templates. R-copiers
should read them and produce mutant copiers. This would demonstrate the full
Darwinian loop: mutation → heredity → genotype-to-phenotype conversion.

### Results

| Reactions | T-cop | R-cop | TmplT | TmplR | Mut inert (sp) | Mut active (sp) | DAEEE mut |
|-----------|-------|-------|-------|-------|----------------|-----------------|-----------|
| 0 | 5 | 5 | 10 | 10 | 0 (0) | 0 (0) | 0 |
| 50,000 | 47 | 22 | 10 | 4 | 4 (3) | 7 (7) | 0 |
| 100,000 | 99 | 35 | 56 | 8 | 8 (6) | 10 (10) | 0 |
| 150,000 | 152 | 39 | 106 | 15 | 14 (11) | 21 (21) | 1 |
| 200,000 | 185 | 45 | 225 | 25 | 22 (17) | 29 (29) | 2 |
| 300,000 | 274 | 54 | 383 | 33 | 50 (34) | 49 (45) | 6 |
| 400,000 | 325 | 52 | 642 | 47 | 98 (65) | 77 (69) | 16 |

At 400k reactions, total population = 1,241 molecules (454 active + 787 inert).

### DAEEE mutant templates at 400k

11 distinct species, 16 total copies. All are truncations of Template_T
(breaks cutting off the tail end while preserving the DAEEE prefix).

### Darwinian pairs found: 3

A "Darwinian pair" is a mutant template with a matching mutant copier — evidence
that the R-copier read the mutant template and produced the corresponding
mutant copier.

| Template len | Body len | Template qtt | Copier count | Copier properties |
|-------------|----------|-------------|--------------|-------------------|
| 128 | 123 | 1 | 1 | 90% T-copier, has grab+release+factory. Parasitic: releases copy but consumes original template. |
| 114 | 109 | 2 | 2 | 80% T-copier, has grab+factory, no release. One-shot: grabs then gets stuck. |
| 81 | 76 | 1 | 1 | 55% T-copier, has grab+factory. Too truncated to function. |

The 123-char parasitic copier is particularly notable: it's a functional template
consumer that grabs templates, copies them, releases the copy, but doesn't
release the original (missing the second release place). This is an emergent
parasitic strategy.

### Conclusion

**Darwinian evolution confirmed.** The full information chain works:

1. **Mutation**: Template_T breaks at a random position → DAEEE + truncated body
   (mutant template, still inert and grabbable)
2. **Template heredity**: T-copier grabs mutant template → copies it exactly →
   mutant template population grows
3. **Genotype → Phenotype**: R-copier grabs mutant template → skips DAEEE →
   copies body → new mutant copier (active molecule with Petri net)

Most mutant copiers are non-functional parasites (truncations are usually
deleterious), which is the expected outcome. For beneficial mutations, point
mutations from collisions or longer evolutionary runs would be needed.

## Technical notes

- **Snapshot analysis pitfall**: Active molecules (copiers) are stored in
  `areactants` as `[mol, pnets_list]` pairs, NOT in `ireactants`. Must check
  both to get correct population counts.
- **Experiment runner bug**: Running two experiment continuations concurrently
  on the same experiment causes UNIQUE constraint failures on snapshot saves.
  Don't run concurrent extensions.
