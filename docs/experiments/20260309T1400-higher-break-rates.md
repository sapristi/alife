# Higher Break Rates and Darwinian Evolution

Date: 2026-03-09

## Context

Previous experiments (72-74) showed that `break_length_exponent=0` (uniform
pressure) produces more Darwinian pairs than the default `exponent=0.5`
(length-dependent breaks), but the difference was small (0-3 pairs at 400k).

This follow-up pushes break rates higher to see whether increased mutation
frequency amplifies Darwinian evolution, and whether the exponent still matters
at high effective break rates.

### 4-component system

| Component | Length | Role |
|-----------|--------|------|
| T-copier | 137 | Grabs DA-templates, copies exactly (including DAEEE) |
| R-copier | 331 | Grabs DA-templates, skips DAEEE, copies body → active copier |
| Template_T | 142 | DAEEE + T-copier (inert) |
| Template_R | 336 | DAEEE + R-copier (inert) |

### Shared parameters

| Parameter | Value |
|-----------|-------|
| transition_rate | 100 |
| grab_rate | 5 |
| collision_rate | 1e-05 |
| Duration | 400k reactions |
| Initial | 5 T-cop, 5 R-cop, 10 TmplT, 10 TmplR + ambient acids |

### Variable parameters

| Exp | break_length_exponent | break_rate | Purpose |
|-----|----------------------|-----------|---------|
| 74 | 0 | 1e-3 | Baseline (from previous report) |
| 78 | 0 | 5e-3 | 5x higher break rate |
| 79 | 0 | 1e-2 | 10x higher break rate |
| 80 | 0.5 | 1e-3 | Length-dependent at same rate as exp 79's effective level |

## Experiment 78: break_exp=0, rate=5e-3

| Reactions | T-cop | R-cop | TmplT | TmplR | DAEEE mut (sp) | Darw pairs |
|-----------|-------|-------|-------|-------|----------------|------------|
| 0 | 5 | 5 | 10 | 10 | 0 (0) | 0 |
| 100,000 | 96 | 35 | 40 | 6 | 0 (0) | 0 |
| 200,000 | 169 | 52 | 137 | 29 | 2 (2) | 1 |
| 300,000 | 264 | 52 | 310 | 23 | 11 (6) | 2 |
| 400,000 | 329 | 56 | 481 | 55 | 22 (13) | 5 |

Final: 2214 total (498 active [104sp], 666 inert [91sp]).
Break effective rate: 5.76, raw rate: 1,153.

## Experiment 79: break_exp=0, rate=1e-2

| Reactions | T-cop | R-cop | TmplT | TmplR | DAEEE mut (sp) | Darw pairs |
|-----------|-------|-------|-------|-------|----------------|------------|
| 0 | 5 | 5 | 10 | 10 | 0 (0) | 0 |
| 100,000 | 93 | 20 | 75 | 12 | 12 (2) | 1 |
| 200,000 | 147 | 20 | 269 | 21 | 55 (10) | 4 |
| 300,000 | 173 | 20 | 483 | 30 | 103 (32) | 9 |
| 400,000 | 183 | 19 | 676 | 50 | 165 (52) | 14 |

Final: 2597 total (436 active [172sp], 1111 inert [214sp]).
Break effective rate: 15.24, raw rate: 1,524.

## Experiment 80: break_exp=0.5, rate=1e-3

| Reactions | T-cop | R-cop | TmplT | TmplR | DAEEE mut (sp) | Darw pairs |
|-----------|-------|-------|-------|-------|----------------|------------|
| 0 | 5 | 5 | 10 | 10 | 0 (0) | 0 |
| 100,000 | 88 | 23 | 66 | 3 | 8 (1) | 1 |
| 200,000 | 156 | 23 | 280 | 7 | 48 (11) | 2 |
| 300,000 | 184 | 23 | 478 | 13 | 115 (33) | 8 |
| 400,000 | 206 | 25 | 678 | 38 | 176 (48) | 17 |

Final: 2604 total (451 active [162sp], 1103 inert [203sp]).
Break effective rate: 16.69, raw rate: 16,687.

## Comparison

| Metric | Exp 74 (0, 1e-3) | Exp 78 (0, 5e-3) | Exp 79 (0, 1e-2) | Exp 80 (0.5, 1e-3) |
|--------|-------------------|-------------------|-------------------|---------------------|
| T-copiers | 319 | 329 | 183 | 206 |
| R-copiers | 60 | 56 | 19 | 25 |
| Template_T | 615 | 481 | 676 | 678 |
| Template_R | 53 | 55 | 50 | 38 |
| DAEEE mutants | 18 (11sp) | 22 (13sp) | 165 (52sp) | 176 (48sp) |
| **Darwinian pairs** | **3** | **5** | **14** | **17** |
| Active species | 77 | 104 | 172 | 162 |
| Inert species | 93 | 91 | 214 | 203 |
| Break eff. rate | 1.25 | 5.76 | 15.24 | 16.69 |

### Darwinian pairs increase with effective break rate

The relationship is clear: more breaks = more mutant templates = more Darwinian
conversion. The Darwinian pair count scales roughly with the effective break rate.

### Exponent matters less than effective rate

Exp 79 (exp=0, rate=1e-2, eff=15.24) and exp 80 (exp=0.5, rate=1e-3, eff=16.69)
have similar effective break rates and produce similar results: 14 vs 17
Darwinian pairs, 172 vs 162 active species. The exponent primarily controls how
break_rate maps to effective rate, not the evolutionary dynamics.

### A dominant parasitic lineage emerges

In both exp 79 and 80, a single mutant dominates: a 177-char truncation of
Template_R (first 177 of 336 chars). Its body (172 chars) is the first 52% of
the R-copier. This truncated R-copier is replicated by the T-copier system:

| Exp | Template qtt | Copier qtt | Total |
|-----|-------------|-----------|-------|
| 79 | 79 | 30 | 109 |
| 80 | 101 | 22 | 123 |

This mutant independently appears in both experiments because the same Template_R
break position produces it deterministically. It represents a parasitic lineage:
the truncated R-copier likely retains the grab mechanism (first ~165 chars of
R-copier include the trigger chain and grab) but lacks the copy/release phases,
making it a template consumer that doesn't produce offspring.

### Higher break rates suppress original copiers

At high break rates, original copier populations decline. T-copiers drop from
329 (exp 78) to 183 (exp 79). R-copiers are hit hardest: 56 → 19. R-copiers
are more vulnerable because they're longer (331 vs 137 chars) and their copy
cycle takes longer (more transitions needed), so they spend more time in a
vulnerable active state.

## Top Darwinian pairs in exp 79

| Template | Tmpl qtt | Copier qtt | Origin | Prefix match |
|----------|---------|-----------|--------|-------------|
| len=177 | 79 | 30 | R-cop truncation (52%) | 172/331 |
| len=20 | 6 | 1 | T-cop truncation (11%) | 15/137 |
| len=76 | 3 | 1 | T-cop truncation (52%) | 71/137 |
| len=29 | 3 | 1 | T-cop truncation (18%) | 24/137 |
| len=18 | 3 | 1 | T-cop truncation (9%) | 13/137 |
| len=114 | 2 | 1 | T-cop truncation (79%) | 109/137 |
| len=137 | 1 | 1 | T-cop truncation (96%) | 132/137 |

Most Darwinian pairs are T-copier truncations of varying lengths. Only the
dominant len=177 mutant comes from R-copier. The 137-char near-full-length
T-copier truncation (96% match) is the closest to a potentially functional
mutant copier.

## Conclusions

1. **Effective break rate is the primary driver of Darwinian evolution.** Both
   exponent settings produce similar evolutionary dynamics when matched for
   effective rate.

2. **There is a trade-off between mutation rate and copier survival.** At
   break_rate=1e-2 (exp 79), R-copiers drop to 19 (from 60 at 1e-3). Higher
   still would likely kill the replication system entirely.

3. **A reproducible parasitic lineage emerges.** The 177-char R-copier
   truncation appears independently in both high-break experiments, suggesting
   a deterministic hotspot in the Template_R sequence.

4. **Most mutant copiers are non-functional truncations.** The Darwinian
   pathway produces many genotype→phenotype conversions, but nearly all result
   in parasitic or inert copiers. Beneficial mutations likely require point
   mutations (from collisions) rather than truncations (from breaks).
