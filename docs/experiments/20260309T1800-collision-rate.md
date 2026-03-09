# Collision Rate Experiments

Date: 2026-03-09

## Context

Previous experiments showed that break reactions produce truncation mutations —
cutting molecules shorter. These truncations create many DAEEE mutant templates
and Darwinian pairs, but nearly all mutant copiers are non-functional (missing
essential components from the tail end).

Collisions produce point mutations (recombination between two molecules) rather
than truncations. This could yield more diverse mutations, including ones that
preserve molecule length while changing internal structure. The question: does
increasing collision rate improve Darwinian evolution?

All experiments use the same base configuration as exp 74: break_length_exponent=0,
break_rate=1e-3, with only collision_rate varying.

### Shared parameters

| Parameter | Value |
|-----------|-------|
| transition_rate | 100 |
| grab_rate | 5 |
| break_rate | 0.001 |
| break_length_exponent | 0 |
| Duration | 400k reactions |
| Initial | 5 T-cop, 5 R-cop, 10 TmplT, 10 TmplR + ambient acids |

### Variable parameters

| Exp | collision_rate | vs baseline (1e-5) |
|-----|---------------|-------------------|
| 74 | 1e-5 | baseline |
| 87 | 2e-5 | 2x |
| 85 | 5e-5 | 5x |
| 84 | 1e-4 | 10x (engine crash) |
| 81-83 | 1e-3 to 1e-1 | 100x-10000x (system dies immediately) |

## Results

### Experiment 87: coll=2e-5 (2x baseline)

| Reactions | T-cop | R-cop | TmplT | TmplR | DAEEE mut (sp) | Darw pairs |
|-----------|-------|-------|-------|-------|----------------|------------|
| 0 | 5 | 5 | 10 | 10 | 0 (0) | 0 |
| 100,000 | 98 | 25 | 95 | 3 | 1 (1) | 0 |
| 200,000 | 164 | 30 | 345 | 12 | 9 (4) | 1 |
| 300,000 | 204 | 29 | 585 | 29 | 39 (24) | 3 |
| 400,000 | 240 | 27 | 804 | 25 | 70 (41) | 8 |

Final: active 400 [124sp], inert 1254 [264sp].
Break eff: 1.63, Coll eff: 79.84.

### Experiment 85: coll=5e-5 (5x baseline)

| Reactions | T-cop | R-cop | TmplT | TmplR | DAEEE mut (sp) | Darw pairs |
|-----------|-------|-------|-------|-------|----------------|------------|
| 0 | 5 | 5 | 10 | 10 | 0 (0) | 0 |
| 100,000 | 23 | 5 | 129 | 7 | 34 (25) | 2 |
| 200,000 | 6 | 0 | 65 | 3 | 80 (58) | 2 |
| 300,000 | 1 | 0 | 22 | 2 | 88 (60) | 3 |
| 400,000 | 0 | 0 | 4 | 0 | 51 (36) | 0 |

Final: active 355 [344sp], inert 2805 [1864sp].
Break eff: 3.10, Coll eff: 435.65.

### Experiments 84, 81-83: coll >= 1e-4

All killed the replication system before 100k reactions. Exp 84 (coll=1e-4)
also triggered an engine crash: collisions created molecules whose Petri nets
entered invalid states (`place.ml: cannot pop No_token`). This is an engine bug
exposed by high collision rates.

## Comparison

| Metric | Exp 74 (1e-5) | Exp 87 (2e-5) | Exp 85 (5e-5) |
|--------|---------------|---------------|---------------|
| T-copiers | 319 | 240 | 0 |
| R-copiers | 60 | 27 | 0 |
| Template_T | 615 | 804 | 4 |
| Template_R | 53 | 25 | 0 |
| DAEEE mutants | 18 (11sp) | 70 (41sp) | 51 (36sp) |
| **Darwinian pairs** | **3** | **8** | **0** |
| Active species | 77 | 124 | 344 |
| Inert species | 93 | 264 | 1,864 |
| Coll eff. rate | 29.35 | 79.84 | 435.65 |

### Darwinian pairs in exp 87

| Template | Tmpl qtt | Copier qtt | Origin | Type |
|----------|---------|-----------|--------|------|
| len=23 | 10 | 2 | T-cop truncation (13%) | break |
| len=54 | 4 | 1 | T-cop truncation (36%) | break |
| len=19 | 2 | 1 | T-cop truncation (10%) | break |
| len=22 | 2 | 1 | T-cop truncation (12%) | break |
| len=37 | 2 | 1 | T-cop truncation (23%) | break |
| len=39 | 2 | 1 | T-cop truncation (25%) | break |
| len=51 | 2 | 1 | T-cop truncation (34%) | break |
| len=77 | 2 | 1 | T-cop truncation (52%) | break |

All 8 Darwinian pairs are still truncation products from breaks, not collision
point mutations. The increased collision rate doesn't produce collision-derived
Darwinian pairs — it produces more diversity and more inert species, which
indirectly increases the pool of break fragments available for Darwinian
conversion.

## Key findings

1. **Collision rate has a very narrow useful window.** 2x baseline (2e-5) is
   the sweet spot: copiers survive (240 T, 27 R) and Darwinian pairs increase
   from 3 to 8. At 5x (5e-5), copiers go extinct. At 10x+, the system dies
   immediately or the engine crashes.

2. **Collisions are far more destructive than breaks.** Doubling collision rate
   has more impact than 10x-ing break rate (compare exp 87 vs exp 79). This is
   because collisions recombine two molecules, potentially corrupting both,
   while breaks only destroy one molecule and produce usable fragments.

3. **No collision-derived Darwinian pairs observed.** All Darwinian pairs in
   exp 87 are break truncations. Collisions create massive species diversity
   (124 active species vs 77 baseline, 264 inert species vs 93) but the
   recombined molecules don't preserve the DAEEE prefix needed for the
   Darwinian pathway. For a collision to produce a viable mutant template, it
   would need to recombine in a way that preserves both the DAEEE prefix and
   enough copier body to be functional — a very narrow target.

4. **Collisions accelerate inert diversity.** Exp 87 has 264 inert species
   (vs 93 baseline) and exp 85 reaches 1,864. This molecular soup could be
   a substrate for more complex evolutionary dynamics in longer runs.

5. **Engine bug at high collision rates.** Collisions can create molecules
   whose Petri nets have invalid states, causing `cannot pop No_token` errors.
   This needs fixing for robustness.

## Conclusion

Higher collision rates are not the path to functional mutant copiers. The
mutation they produce is too disruptive — scrambling entire molecules rather
than making targeted changes. The replication system is fragile: copier
molecules must be precisely structured to function, and even small
recombinations destroy them.

For beneficial mutations, the system likely needs either:
- Much longer runs at low collision rates (rare lucky recombinations)
- A different mutation mechanism (single-acid substitution)
- More robust copier designs that tolerate partial corruption
