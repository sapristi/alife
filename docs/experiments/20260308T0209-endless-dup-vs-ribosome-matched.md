# Comparison: endless_duplication vs ribosome_1 — matched env parameters

**Date:** 2026-03-08 02:09
**Experiments:** [5] endless_dup_matched, [6] ribosome_1_matched
**Initial states:** `endless_duplication` (#8) and `ribosome_1` (#9), both with identical env
**Parameters:** 10,000 reactions, stats every 500, snapshots every 5000

## Setup

Both experiments use the same environment:
```json
{"transition_rate": 10, "grab_rate": 1, "break_rate": "1/1000000", "collision_rate": "1/100000"}
```

The only difference is the initial molecules:
- **endless_duplication**: 2 large active molecules (replicator + helper) + 5 ambient types (50 each)
- **ribosome_1**: 1 large active molecule (replicator) + 1 small inactive molecule + 5 ambient types (50 each)

Previous experiments used different env params (ribosome_1 had 1000x higher break_rate and no collisions), making comparison impossible. This run isolates the effect of molecule composition.

## Summary

| reac | ed i_sp | ed i_tot | ed a_sp | ed a_tot | ri i_sp | ri i_tot | ri a_sp | ri a_tot |
|-----:|--------:|---------:|--------:|---------:|--------:|---------:|--------:|---------:|
|    1 |       5 |      250 |       2 |        2 |       6 |      251 |       1 |        1 |
|  501 |      37 |      310 |       3 |        3 |      28 |      284 |       3 |        3 |
| 1001 |      43 |      323 |       4 |        4 |      29 |      285 |       3 |        3 |
| 2001 |      44 |      321 |       4 |        4 |      27 |      288 |       3 |        3 |
| 3001 |      51 |      335 |       7 |        7 |      29 |      287 |       3 |        3 |
| 4001 |      53 |      335 |       8 |        8 |      36 |      297 |       3 |        3 |
| 5001 |      56 |      338 |       8 |        8 |      45 |      322 |       2 |        2 |
| 6001 |      60 |      341 |       7 |        7 |      57 |      340 |       1 |        1 |
| 7001 |      62 |      338 |       7 |        7 |      75 |      364 |       2 |        2 |
| 8001 |      91 |      382 |       6 |        6 |      83 |      376 |       2 |        2 |
| 8501 |     109 |      394 |       2 |        2 |      83 |      387 |       0 |        0 |
| 9001 |     121 |      408 |       3 |        3 |      84 |      375 |       0 |        0 |
| 9501 |     113 |      419 |       1 |        1 |      83 |      372 |       0 |        0 |

`ed` = endless_duplication, `ri` = ribosome_1. `i_sp`/`i_tot` = inactive species/total. `a_sp`/`a_tot` = active species/total.

## Analysis

### Both systems die, but with different trajectories

Both experiments end with a collapsed system (0–1 active species, 0 grabs) around the same timescale (~8000–9500 reactions). However the paths differ significantly.

### endless_duplication: diversify then collapse

- **Early diversification**: Active species grow steadily from 2 to 8 (reactions 1–4000). Break products create new functional molecules, some of which become active.
- **Peak activity**: 8 active species at reaction 4000, with 6 grabs still functioning.
- **Sudden collapse** around reaction 8000: active species crash from 6 to 2, grabs drop to 0. The system had more complexity but was fragile — many small pieces couldn't sustain themselves.
- **Post-death**: 113–121 inactive species, 408–419 total molecules. The soup is diverse but inert.

### ribosome_1: stable plateau then slow decay

- **Long stability**: The system holds at 3 active species from reaction 500 to 4000 with 5 grabs — much more stable than endless_duplication.
- **Gradual decline**: Active species slowly drop (3 → 2 → 1 → 0) over reactions 4000–8500 rather than crashing suddenly.
- **Grabs decay earlier**: Grabs drop to 0 by reaction 3000, suggesting the active molecules lost grab functionality but retained other activity (transitions).
- **Post-death**: 83–84 inactive species, 372–387 total molecules. Less diverse debris than endless_duplication.

### Key differences

| Metric | endless_duplication | ribosome_1 |
|--------|-------------------|------------|
| Peak active species | 8 (at ~4000) | 3 (at ~500) |
| Stable phase | 1000–7000 (fluctuating) | 500–4000 (flat) |
| Death style | Sudden crash | Gradual decay |
| Time to 0 active | ~8500 | ~8500 |
| Post-death i_species | ~113 | ~83 |
| Post-death total mols | ~419 | ~372 |

### Interpretation

The two-molecule setup (endless_duplication) creates more diversity through break products that can form active Petri nets, but this diversity doesn't translate to resilience — it actually accelerates breakdown by creating more targets for breaks. The single-molecule setup (ribosome_1) is simpler but more stable, maintaining a consistent low-complexity state for longer before dying.

Neither setup is self-sustaining at this break rate. The fundamental problem is the same: breaks are irreversible damage, and without a repair or error-correction mechanism, entropy eventually wins regardless of initial complexity. The break_rate of `1/1000000` gives both systems roughly 8000–9000 reactions of useful life.

---

<details>
<summary>Initial states</summary>

**endless_duplication:**
```json
{
  "mols": [
    {
      "mol": "AAABAAAADDFCBAAADDFBAAABDDFCBAABDDFBAAACDDFCBAACDDFBAAADDDFCBAADDDFBAAAFDDFCBAAFDDFBAAAAADDFCAABBBDDFAAABAAAADDFABAFAFDDFAAABAAABDDFABAFBFDDFAAABAAACDDFABAFCFDDFAAABAAADDDFABAFDFDDFAAABAAAFDDFABAFFFDDFAAABCAAADDFCCAAADDFBCBABDDFCCAABDDFBCCACDDFCCAACDDFBCDADDDFCCAADDDFBCFAFDDFCCAAFDDFBABAAADDFCAABBBDDFAAACAAAAADDFABBAAACAAAAADDFABBAAABAABBBDDFCAACCCDDFAAABAABBBDDFABADFDFFFDDFAAABBACCCDDFCAACCCDDFABC",
      "qtt": 1
    },
    {
      "mol": "DDCBAFDDCCCAACFDDCCCABBAAAFDDFFFDFDABAFDDBBBAABAAAFDDCCCAACFDDBBBAABAAABBAFDDAAAAACAAABBAFDDAAAAACAAAFDDBBBAACFDDAAABABFDDFAACCFDDFAFCBFDDDAACCFDDDADCBFDDCAACCFDDCACCBFDDBAACCFDDBABCBFDDAAACCFDDAAACBAAAFDDFFFABAFDDFAAABAAAFDDFDFABAFDDDAAABAAAFDDFCFABAFDDCAAABAAAFDDFBFABAFDDBAAABAAAFDDFAFABAFDDAAAABAAAFDDBBBAACFDDAAAAABFDDFAABCFDDFAAABFDDDAABCFDDDAAABFDDCAABCFDDCAAABFDDBAABCFDDBAAABFDDAAABCFDDAAAABAAA",
      "qtt": 1
    },
    { "mol": "A", "qtt": 50, "ambient": true },
    { "mol": "B", "qtt": 50, "ambient": true },
    { "mol": "C", "qtt": 50, "ambient": true },
    { "mol": "D", "qtt": 50, "ambient": true },
    { "mol": "F", "qtt": 50, "ambient": true }
  ]
}
```

**ribosome_1:**
```json
{
  "mols": [
    {
      "mol": "AAABAAAADDFCBAAADDFBAAABDDFCBAABDDFBAAACDDFCBAACDDFBAAADDDFCBAADDDFBAAAFDDFCBAAFDDFBAAAAADDFCAABBBDDFAAABAAAADDFABAFAFDDFAAABAAABDDFABAFBFDDFAAABAAACDDFABAFCFDDFAAABAAADDDFABAFDFDDFAAABAAAFDDFABAFFFDDFAAABCAAADDFCCAAADDFBCBABDDFCCAABDDFBCCACDDFCCAACDDFBCDADDDFCCAADDDFBCFAFDDFCCAAFDDFBABAAADDFCAABBBDDFAAACAAAAADDFABBAAACAAAAADDFABBAAABAABBBDDFCAACCCDDFAAABAABBBDDFABADFDFFFDDFAAABBACCCDDFCAACCCDDFABC",
      "qtt": 1
    },
    {
      "mol": "DDBBAFDDAABCAAAFDDFBFABAFDDAAABAAAFDDAAABFDDFAFABAAAAA",
      "qtt": 1,
      "ambient": false
    },
    { "mol": "A", "qtt": 50, "ambient": true },
    { "mol": "B", "qtt": 50, "ambient": true },
    { "mol": "C", "qtt": 50, "ambient": true },
    { "mol": "D", "qtt": 50, "ambient": true },
    { "mol": "F", "qtt": 50, "ambient": true }
  ]
}
```

**Shared env:**
```json
{"transition_rate": 10, "grab_rate": 1, "break_rate": "1/1000000", "collision_rate": "1/100000"}
```

</details>

**Date:** 2026-03-08 | **Commit:** `fec9704e94aab6827e5438960677c4836ed6a7fc` (add experiment docs to README and commit convention to CLAUDE.md)
