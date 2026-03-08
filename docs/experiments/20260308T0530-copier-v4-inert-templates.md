# Copier v4: Inert template self-replicating system

**Date:** 2026-03-08 05:30
**Experiments:** #55 (clean), #56 (mutations grab=1), #57-58 (mutations grab=5/10, pending)
**Initial state:** InitialState [14] copier_v4_inert_fixed

## Goal

Build a full self-replicating system where both templates AND copiers reproduce, then test with break/collision mutations to evaluate potential for Darwinian evolution.

## System design

| Component | Length | Role |
|-----------|--------|------|
| T-copier | 401 | Active. Grabs DA-prefixed molecules, copies exactly → new inert template. |
| R-copier | 600 | Active. Grabs DA-prefixed molecules, skips DAEEE prefix, copies body → new copier. |
| Template_T | 406 | Inert (DAEEE prefix, EEE=stop_interpretation). Encodes T-copier. |
| Template_R | 605 | Inert (DAEEE prefix). Encodes R-copier. |

**Key design decisions:**
- DAEEE prefix makes templates inert — no Petri net, no competing reactions
- Grab pattern `^(D)A.*?$` requires "DA" start, excluding bare "D" molecules and copiers (which start with "A")
- R-copier uses 5-step trigger chain (T_SKIP1→T_SKIP5) to skip DAEEE prefix before copying
- T_SKIP1 borrows a split token from P11 (token factory) to produce both cursor advance and trigger output

**Fixes applied during development:**
1. `max_group_length` 5→6 in engine (for 6-char grab pattern FDFAFF)
2. Token shortage in R-copier: T_SKIP1 had 1 input token but 2 output arcs; fixed by adding ia_split from P11

## Initial state

- 5 T-copiers, 5 R-copiers, 10 Template_T, 10 Template_R
- 200 ambient each of A/B/C/E/F, 50 ambient D
- Base env: transition_rate=100, grab_rate=1, break_rate=0, collision_rate=0

## Results

### Experiment 55: Clean replication (grab=5, no mutations)

| reac | a_sp | a_cnt | i_sp | i_cnt | grabs | trans |
|-----:|-----:|------:|-----:|------:|------:|------:|
| 1 | 2 | 10 | 8 | 1070 | 80 | 10 |
| 10k | 2 | 11 | 7 | 1052 | 77 | 11 |
| 30k | 2 | 20 | 6 | 1050 | 120 | 20 |
| 50k | 2 | 31 | 6 | 1050 | 186 | 31 |
| 100k | 2 | 53 | 6 | 1050 | 318 | 53 |
| 140k | 2 | 68 | 6 | 1050 | 408 | 68 |
| 200k | 2 | 87 | 6 | 1050 | 522 | 87 |

**Final state at 200k:** T-copier count=56, R-copier count=31.

**Analysis:** Both copier types replicate successfully. Templates are consumed faster than produced — by 20k reactions all free templates are "in use" (grabbed by copiers mid-cycle). The template pool acts as a bottleneck: 20 templates cycle through 87 copiers, each needing ~400 transitions per copy. Growth is steady but sublinear due to template contention.

### Experiment 56: With mutations (grab=1, break=1/1M, collision=1/100k)

| reac | a_sp | a_cnt | i_sp | i_cnt | grabs | trans | breaks | colls |
|-----:|-----:|------:|-----:|------:|------:|------:|-------:|------:|
| 1 | 2 | 10 | 8 | 1070 | 80 | 10 | 18 | 18 |
| 10k | 4 | 14 | 113 | 1170 | 91 | 14 | 127 | 127 |
| 20k | 9 | 18 | 266 | 1361 | 150 | 18 | 284 | 284 |
| 50k | 12 | 24 | 652 | 1958 | 410 | 24 | 676 | 676 |
| 70k | 18 | 29 | 888 | 2367 | 424 | 29 | 917 | 917 |
| 90k | 22 | 32 | 1179 | 2886 | 544 | 32 | 1211 | 1211 |

**Active species at 100k (22 species):**

| Species | Length | Count | Origin |
|---------|--------|-------|--------|
| T-copier (original) | 401 | 8 | Replicated by R-copier |
| R-copier (original) | 600 | 3 | Replicated by R-copier |
| R-copier variant | 600 | 2 | Break/collision product |
| 18 novel species | 61-573 | 1 each | Break/collision fragments |

**Inert pool:** 1330 non-ambient types, dominated by short 2-char fragments (FC=28, AC=24, BF=22, etc.) from break reactions.

## Evolution analysis

### Variation
**Present.** Break and collision reactions create new molecular variants. 22 active species emerged from 2 original designs. Most are fragments or recombination products with novel Petri nets.

### Heredity
**Partial.** Original copiers replicate faithfully via the template system (T-copier→Template_T, R-copier→Template_R). However, mutant active molecules are NOT replicated — they lack corresponding templates. Mutant species are singletons (count=1), created by mutation but not copied.

For full heredity, a mutant would need to:
1. Have its own template (DAEEE + mutant body) created somehow
2. Be recognized and copied by existing copiers

This is unlikely in the current design because templates must exactly match the grab pattern, and new templates would need to be created by collision or break events combining DAEEE with a mutant body.

### Selection
**Weak.** Replicators (original copiers) maintain stable populations while non-replicating mutants appear transiently. This is survival-of-the-replicating, not differential fitness among replicators.

### Verdict
The system exhibits **open-ended molecular diversification** (new species continuously emerge) and **replication with fidelity** (originals maintain population). However, it does NOT yet show **evolution by natural selection** because:
1. Variation doesn't affect replication fitness (mutants don't replicate)
2. There's no competition between replicator variants
3. Heredity is template-based, not self-based — mutations to copiers aren't inherited

The system is analogous to a **copying machine that runs while junk accumulates around it**, rather than a population of organisms evolving.

## Comparison with previous designs

| Design | Self-sustaining? | Copier replication? | Molecular diversity? |
|--------|-----------------|--------------------|--------------------|
| v2 (T-copier only, experiment #28) | Yes (200k+) | No (template-only) | Yes (77 active species) |
| v3 (active templates) | No (all died) | N/A | N/A |
| **v4 (inert templates)** | **Yes** | **Yes (both types)** | **Yes (22+ species)** |

v4 is the first design where both copiers AND templates replicate, creating a true self-replicating system.

## Next steps

- Run experiments 57-58 (higher grab rates with mutations) to completion
- Run longer experiments (500k-1M reactions) to see if mutant copiers emerge
- Consider design changes to enable heritable variation:
  - Allow copiers to copy arbitrary DA-prefixed molecules (not just existing templates)
  - Reduce template specificity so mutant molecules can serve as templates
  - Add a mechanism for "template creation" where a DAEEE prefix gets added to a molecule by collision

<details>
<summary>Initial state JSON</summary>

```json
{
  "mols": [
    {"mol": "AAAABAFDFAFFDDFBAAADDFAAABCABDDFCCABDDFBCBCDDFCCACDDFBCCDDDFCCADDDFBCDFDDFCCAFDDFBCFABDDFCCAABDDFBCEAFDDFCCAAFDDFBABACDDFCAAADDFAAAABAFAFDDFBAABDDFAAAABAFBFDDFBAACDDFAAAABAFCFDDFBAADDDFAAAABAFDFDDFBAAFDDFAAAABAFFFDDFBAAABDDFAAAABAFEFDDFBAAAFDDFAAABAABDDFCBABDDFBAACDDFCBACDDFBAADDDFCBADDDFBAAFDDFCBAFDDFBAAABDDFCBAABDDFBAAAFDDFCBAAFDDFBAAACDDFCAAADDDFAAAABBCAAACDDFAAAABBCAAACDDFAAAABCBBAADDDFCAAADDDF", "qtt": 5},
    {"mol": "AAAABAFDFAFFDDFBAAADDFAAABCABDDFCCABDDFBCBCDDFCCACDDFBCCDDDFCCADDDFBCDFDDFCCAFDDFBCFABDDFCCAABDDFBCEAFDDFCCAAFDDFBCDAEDDFCCAAEDDFBCABADDFCCABADDFBCEBBDDFCCABBDDFBCEBCDDFCCABCDDFBCEBDDDFCCABDDDFBABACDDFCAAADDFAAAABAFAFDDFBAABDDFAAAABAFBFDDFBAACDDFAAAABAFCFDDFBAADDDFAAAABAFDFDDFBAAFDDFAAAABAFFFDDFBAAABDDFAAAABAFEFDDFBAAAFDDFAAABACAEDDFBAABDDFCBABDDFBAACDDFCBACDDFBAADDDFCBADDDFBAAFDDFCBAFDDFBAAABDDFCBAABDDFBAAAFDDFCBAAFDDFBAAACDDFCAAADDDFAAAABBCAAACDDFAAAABBCAAACDDFAAAABCBBAAEDDFCAAAEDDFBBAADDDFCAAADDDFAAACAAAEDDFBAABADDFAAACAABADDFBAABBDDFAAACAABBDDFBAABCDDFAAACAABCDDFBAABDDDFAAACAABDDDFBAAADDDF", "qtt": 5},
    {"mol": "DAEEEAAAABAFDFAFFDDFBAAADDFAAABCABDDFCCABDDFBCBCDDFCCACDDFBCCDDDFCCADDDFBCDFDDFCCAFDDFBCFABDDFCCAABDDFBCEAFDDFCCAAFDDFBABACDDFCAAADDFAAAABAFAFDDFBAABDDFAAAABAFBFDDFBAACDDFAAAABAFCFDDFBAADDDFAAAABAFDFDDFBAAFDDFAAAABAFFFDDFBAAABDDFAAAABAFEFDDFBAAAFDDFAAABAABDDFCBABDDFBAACDDFCBACDDFBAADDDFCBADDDFBAAFDDFCBAFDDFBAAABDDFCBAABDDFBAAAFDDFCBAAFDDFBAAACDDFCAAADDDFAAAABBCAAACDDFAAAABBCAAACDDFAAAABCBBAADDDFCAAADDDF", "qtt": 10},
    {"mol": "DAEEEAAAABAFDFAFFDDFBAAADDFAAABCABDDFCCABDDFBCBCDDFCCACDDFBCCDDDFCCADDDFBCDFDDFCCAFDDFBCFABDDFCCAABDDFBCEAFDDFCCAAFDDFBCDAEDDFCCAAEDDFBCABADDFCCABADDFBCEBBDDFCCABBDDFBCEBCDDFCCABCDDFBCEBDDDFCCABDDDFBABACDDFCAAADDFAAAABAFAFDDFBAABDDFAAAABAFBFDDFBAACDDFAAAABAFCFDDFBAADDDFAAAABAFDFDDFBAAFDDFAAAABAFFFDDFBAAABDDFAAAABAFEFDDFBAAAFDDFAAABACAEDDFBAABDDFCBABDDFBAACDDFCBACDDFBAADDDFCBADDDFBAAFDDFCBAFDDFBAAABDDFCBAABDDFBAAAFDDFCBAAFDDFBAAACDDFCAAADDDFAAAABBCAAACDDFAAAABBCAAACDDFAAAABCBBAAEDDFCAAAEDDFBBAADDDFCAAADDDFAAACAAAEDDFBAABADDFAAACAABADDFBAABBDDFAAACAABBDDFBAABCDDFAAACAABCDDFBAABDDDFAAACAABDDDFBAAADDDF", "qtt": 10},
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
    "collision_rate": 0
  }
}
```

</details>

**Git:** 1df3ef1
**Date:** 2026-03-08
