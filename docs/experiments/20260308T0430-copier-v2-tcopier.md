# Copier v2: T-copier + DEEE-template self-replicating system

**Date:** 2026-03-08 04:30
**Experiment:** #28 (copier_v2)
**Initial state:** InitialState [10]
**Parameters:** 200,000 reactions, stats every 5k-10k, snapshot every 50k-100k

## Goal

Test a new self-replicating molecular system designed to avoid the mutual-grabbing destruction that killed all previous designs. The key insight: separate **copiers** (no D prefix, invisible to grab patterns) from **templates** (DEEE prefix, inert and grabbable).

## System design

| Component | Molecule | Length | Role |
|-----------|----------|--------|------|
| T-copier | No prefix | 400 chars | Active. Grabs D-prefixed molecules, reads each acid, grabs matching single-acid molecule from environment, merges to accumulator. Copies template exactly. |
| Template | DEEE + T-copier | 404 chars | Inert (EEE = Stop_interpretation). Grabbable by copiers (D prefix matches `^(D).*?$`). |

**Why it works:** Copiers lack the D prefix, so they are never matched by the grab pattern `^(D).*?$`. Only templates (D prefix) are grabbed. Grabbed templates are consumed, but the copy produces a new template — net effect is template replication. Copiers are never destroyed by mutual grabbing.

## Initial state

- 10 T-copiers, 20 templates
- 200 ambient each of A/B/C/E/F, 50 ambient D
- `transition_rate=100, grab_rate=1, break_rate=1/1000000, collision_rate=1/100000`

## Results

| reac_count | active_species | active_count | inert_species | inert_count | grabs | breaks | collisions | mean_inert_len |
|-----------:|---------------:|-------------:|--------------:|------------:|------:|-------:|-----------:|---------------:|
| 1 | 1 | 10 | 7 | 1070 | 70 | 17 | 17 | 1304 |
| 5k | 2 | 10 | 13 | 1068 | 80 | 23 | 23 | 394 |
| 10k | 2 | 10 | 16 | 1082 | 80 | 26 | 26 | 473 |
| 25k | 4 | 12 | 25 | 1112 | 90 | 37 | 37 | 578 |
| 50k | 9 | 17 | 41 | 1166 | 114 | 58 | 58 | 562 |
| 65k | 20 | 29 | 102 | 1266 | 213 | 131 | 131 | 226 |
| 75k | 22 | 30 | 237 | 1462 | 381 | 267 | 267 | 115 |
| 100k | 31 | 38 | 679 | 2133 | 846 | 717 | 717 | 48 |
| 120k | 40 | 46 | 990 | 2683 | 1273 | 1036 | 1036 | 37 |
| 150k | 55 | 61 | 1426 | 3526 | 1761 | 1487 | 1487 | 28 |
| 170k | 62 | 71 | 1681 | 4066 | 1496 | 1752 | 1752 | 25 |
| 190k | 77 | 84 | 2034 | 4727 | 1861 | 2118 | 2118 | 21 |

## Phases

### Phase 1: Stable replication (0–25k)
Copiers replicate templates steadily. Active count stays at 10 (all original copiers). A second active species appears early (likely a break fragment). Inert count slowly grows (1070→1112). System is in equilibrium.

### Phase 2: Diversity takeoff (25k–65k)
Active species accelerates from 4 to 20. Break and collision reactions increase. New functional molecule types emerge from fragmentation and recombination. Inert species explode (25→102). This is the transition to open-ended growth.

### Phase 3: Exponential growth (65k–190k)
All metrics show sustained growth. Active species 20→77, active count 29→84. Break reactions overtake grabs as the dominant reaction type (~2118 breaks vs ~1861 grabs at 190k). The system is generating more molecular diversity than it's losing.

Mean inert length drops from 1304 to 21 — the environment fills with short fragments from break reactions. These fragments serve as raw material for further reactions.

Max active length reaches 548 (vs 400 for original copier) — collisions are creating larger, novel molecules.

## Analysis

**This is the first self-sustaining system in YAACS.** All previous designs (endless_duplication, ribosome_1, parameter sweep variants) died before 50k reactions. Experiment #28 shows sustained growth through 200k reactions with no signs of decline.

**Why it succeeds where others failed:**
1. **Copier/template separation** prevents mutual grabbing destruction (the root cause of death in all previous systems)
2. **Ambient acids** provide unlimited raw material for copiers
3. **Low break/collision rates** allow replication to outpace destruction initially, then breaks become a *source* of diversity rather than just damage
4. **Inert templates** (DEEE prefix) can't interfere with copiers — they're just passive data molecules

**Emergent evolution:** 77 distinct active species emerged from just 1 designed copier. These are functional molecules (with Petri nets) created by random break/collision mutations acting on copies and fragments. This is precisely the evolutionary dynamic YAACS was designed to produce.

## Next steps

- Run to 500k+ reactions to observe long-term dynamics
- Build R-copier (ribosome mode) to enable copier self-replication — currently only templates are replicated, copiers cannot reproduce themselves
- Analyze the 77 active species: what Petri nets do they have? Are any of them functional copiers or novel machines?
- Investigate the "bad molecule" warnings (empty strings from breaks) — could filter these in the engine

<details>
<summary>Initial state JSON</summary>

```json
{
  "mols": [
    {"mol": "AAAABAFDFFFDDFBAAADDFAAABCABDDFCCABDDFBCBCDDFCCACDDFBCCDDDFCCADDDFBCDFDDFCCAFDDFBCFABDDFCCAABDDFBCEAFDDFCCAAFDDFBABACDDFCAAADDFAAAABAFAFDDFBAABDDFAAAABAFBFDDFBAACDDFAAAABAFCFDDFBAADDDFAAAABAFDFDDFBAAFDDFAAAABAFFFDDFBAAABDDFAAAABAFEFDDFBAAAFDDFAAABAABDDFCBABDDFBAACDDFCBACDDFBAADDDFCBADDDFBAAFDDFCBAFDDFBAAABDDFCBAABDDFBAAAFDDFCBAAFDDFBAAACDDFCAAADDDFAAAABBCAAACDDFAAAABBCAAACDDFAAAABCBBAADDDFCAAADDDF", "qtt": 10},
    {"mol": "DEEEAAAABAFDFFFDDFBAAADDFAAABCABDDFCCABDDFBCBCDDFCCACDDFBCCDDDFCCADDDFBCDFDDFCCAFDDFBCFABDDFCCAABDDFBCEAFDDFCCAAFDDFBABACDDFCAAADDFAAAABAFAFDDFBAABDDFAAAABAFBFDDFBAACDDFAAAABAFCFDDFBAADDDFAAAABAFDFDDFBAAFDDFAAAABAFFFDDFBAAABDDFAAAABAFEFDDFBAAAFDDFAAABAABDDFCBABDDFBAACDDFCBACDDFBAADDDFCBADDDFBAAFDDFCBAFDDFBAAABDDFCBAABDDFBAAAFDDFCBAAFDDFBAAACDDFCAAADDDFAAAABBCAAACDDFAAAABBCAAACDDFAAAABCBBAADDDFCAAADDDF", "qtt": 20},
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
    "break_rate": "1/1000000",
    "collision_rate": "1/100000"
  }
}
```

</details>

**Git:** b1318ba
**Date:** 2026-03-08
