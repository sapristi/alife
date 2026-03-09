# Break Length Exponent Experiments

Date: 2026-03-09

## Context

The break reaction rate formula was parameterized with a configurable exponent:
`rate = (len-1)^exponent * qtt`. With the default `exponent=0.5` (sqrt), longer
molecules break more often. With `exponent=0`, all molecules break at the same
rate regardless of length — creating uniform population pressure while still
producing fragments.

The goal was to assess whether uniform break pressure (`exponent=0`) affects
Darwinian evolution dynamics differently from length-dependent breaks
(`exponent=0.5`).

### 4-component system

| Component | Length | Role |
|-----------|--------|------|
| T-copier | 137 | Grabs DA-templates, copies exactly (including DAEEE) |
| R-copier | 331 | Grabs DA-templates, skips DAEEE, copies body → active copier |
| Template_T | 142 | DAEEE + T-copier (inert) |
| Template_R | 336 | DAEEE + R-copier (inert) |

## Experiment 72: Control (exponent=0.5)

### Parameters

| Parameter | Value |
|-----------|-------|
| transition_rate | 100 |
| grab_rate | 5 |
| break_rate | 0.0001 |
| break_length_exponent | 0.5 |
| collision_rate | 1e-05 |
| Duration | 400k reactions |
| Initial | 5 T-cop, 5 R-cop, 10 TmplT, 10 TmplR + ambient acids |

### Results

| Reactions | T-cop | R-cop | TmplT | TmplR | DAEEE mut (sp) | Darw pairs |
|-----------|-------|-------|-------|-------|----------------|------------|
| 0 | 5 | 5 | 10 | 10 | 0 (0) | 0 |
| 100,000 | 100 | 34 | 53 | 8 | 0 (0) | 0 |
| 200,000 | 184 | 47 | 224 | 17 | 2 (1) | 0 |
| 300,000 | 251 | 61 | 404 | 43 | 7 (5) | 0 |
| 400,000 | 335 | 59 | 583 | 50 | 14 (12) | 0 |

Final: 2293 total (479 active [77sp], 1814 inert [101sp]).
Break effective rate: 1.44, raw rate: 14,434.

## Experiment 73: Uniform pressure (exponent=0, break_rate=1e-4)

### Parameters

Same as exp 72 except `break_length_exponent = 0`.

### Results

| Reactions | T-cop | R-cop | TmplT | TmplR | DAEEE mut (sp) | Darw pairs |
|-----------|-------|-------|-------|-------|----------------|------------|
| 0 | 5 | 5 | 10 | 10 | 0 (0) | 0 |
| 100,000 | 100 | 35 | 52 | 8 | 0 (0) | 0 |
| 200,000 | 198 | 42 | 208 | 24 | 0 (0) | 0 |
| 300,000 | 276 | 48 | 405 | 36 | 5 (3) | 1 |
| 400,000 | 336 | 51 | 641 | 58 | 16 (10) | 2 |

Final: 2350 total (454 active [65sp], 1896 inert [105sp]).
Break effective rate: 0.13, raw rate: 1,278.

Darwinian pairs at 400k:
- Template len=45 (1 copy) → copier (2 copies)
- Template len=128 (2 copies) → copier (1 copy)

## Experiment 74: Uniform pressure + higher break rate (exponent=0, break_rate=1e-3)

### Parameters

Same as exp 73 except `break_rate = 0.001` (10x higher).

### Results

| Reactions | T-cop | R-cop | TmplT | TmplR | DAEEE mut (sp) | Darw pairs |
|-----------|-------|-------|-------|-------|----------------|------------|
| 0 | 5 | 5 | 10 | 10 | 0 (0) | 0 |
| 100,000 | 99 | 35 | 55 | 8 | 0 (0) | 0 |
| 200,000 | 192 | 44 | 210 | 21 | 2 (1) | 0 |
| 300,000 | 250 | 56 | 399 | 42 | 6 (4) | 0 |
| 400,000 | 319 | 60 | 615 | 53 | 18 (11) | 3 |

Final: 2325 total (465 active [77sp], 1860 inert [99sp]).
Break effective rate: 1.25, raw rate: 1,251.

Darwinian pairs at 400k:
- Template len=45 (2 copies) → copier (1 copy)
- Template len=81 (3 copies) → copier (1 copy)
- Template len=100 (1 copy) → copier (2 copies)

## Comparison

| Metric | Exp 72 (0.5, 1e-4) | Exp 73 (0, 1e-4) | Exp 74 (0, 1e-3) |
|--------|---------------------|-------------------|-------------------|
| T-copiers | 335 | 336 | 319 |
| R-copiers | 59 | 51 | 60 |
| Template_T | 583 | 641 | 615 |
| Template_R | 50 | 58 | 53 |
| DAEEE mutants | 14 (12sp) | 16 (10sp) | 18 (11sp) |
| Darwinian pairs | 0 | 2 | 3 |
| Total population | 2,293 | 2,350 | 2,325 |
| Break eff. rate | 1.44 | 0.13 | 1.25 |
| Break raw rate | 14,434 | 1,278 | 1,251 |

### Key observations

1. **Replication is similar across all three.** T-copier and R-copier counts are
   within noise. The exponent change doesn't impair the core replication loop.

2. **Uniform pressure produces more Darwinian pairs** (2-3 vs 0 at 400k). With
   `exponent=0`, short and long molecules break at the same rate. The default
   `exponent=0.5` heavily favors breaking long molecules (R-copier template at
   336 chars gets ~18x the break factor of a 2-char fragment), so most break
   budget goes to long molecules producing tiny fragments rather than
   evolutionarily interesting mid-length breaks.

3. **`exponent=0` with same break_rate drastically reduces effective break rate**
   (0.13 vs 1.44). The raw rate drops from 14,434 to 1,278 because `sqrt(len-1)`
   inflates the raw rate for long molecules. To compensate, increase break_rate
   by ~10x (exp 74: effective rate 1.25, close to control).

4. **DAEEE mutant counts are comparable** (14-18), but the uniform pressure
   variants show more Darwinian conversion of mutant templates into mutant
   copiers.

### Interpretation

The `exponent=0` setting acts as population pressure: every molecule species
faces break risk proportional only to its count, not its length. This removes
the bias where long molecules (copiers, templates) are disproportionately
targeted. The result is more uniform evolutionary dynamics — mutant templates
survive long enough to be copied and converted into mutant copiers.

The trade-off: `exponent=0` requires a higher `break_rate` to maintain the same
effective break frequency, since the raw rate contribution from long molecules
is eliminated.
