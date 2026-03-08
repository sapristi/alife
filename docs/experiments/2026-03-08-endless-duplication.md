# Experiment: endless_duplication — 10,000 reactions

**Date:** 2026-03-08
**Experiment ID:** 3
**Initial state:** `endless_duplication` (InitialState #8)
**Parameters:** 10,000 reactions, stats every 50 (first 1000) then every 500, snapshots at 500/3000

## Summary

| reac | i_species | i_total | a_species | a_total | breaks | collisions | grabs | transitions |
|-----:|----------:|--------:|----------:|--------:|-------:|-----------:|------:|------------:|
|    1 |         5 |     250 |         2 |       2 |      7 |          7 |     5 |           2 |
|   51 |        10 |     256 |         2 |       2 |     12 |         12 |     5 |           2 |
|  101 |        14 |     264 |         2 |       2 |     16 |         16 |     5 |           2 |
|  151 |        20 |     272 |         2 |       2 |     22 |         22 |     5 |           2 |
|  201 |        23 |     275 |         3 |       3 |     26 |         26 |     4 |           3 |
|  251 |        27 |     280 |         3 |       3 |     30 |         30 |     4 |           3 |
|  301 |        30 |     289 |         3 |       3 |     33 |         33 |     4 |           3 |
|  351 |        33 |     296 |         3 |       3 |     36 |         36 |     9 |           3 |
|  401 |        33 |     299 |         3 |       3 |     36 |         36 |     9 |           3 |
|  451 |        34 |     302 |         4 |       4 |     38 |         38 |     5 |           4 |
|  501 |        37 |     310 |         3 |       3 |     40 |         40 |     5 |           3 |
|  551 |        38 |     307 |         4 |       4 |     42 |         42 |     5 |           4 |
|  601 |        41 |     310 |         3 |       3 |     44 |         44 |     5 |           3 |
|  651 |        43 |     317 |         3 |       3 |     46 |         46 |     4 |           3 |
|  701 |        45 |     319 |         3 |       3 |     48 |         48 |     4 |           3 |
|  751 |        43 |     322 |         4 |       4 |     47 |         47 |     9 |           4 |
|  801 |        43 |     322 |         4 |       4 |     47 |         47 |     9 |           4 |
|  851 |        43 |     322 |         4 |       4 |     47 |         47 |     9 |           4 |
|  901 |        43 |     321 |         4 |       4 |     47 |         47 |     9 |           4 |
|  951 |        43 |     321 |         4 |       4 |     47 |         47 |     9 |           4 |
| 1001 |        43 |     323 |         4 |       4 |     47 |         47 |     9 |           4 |
| 1501 |        42 |     319 |         4 |       4 |     46 |         46 |     9 |           4 |
| 2001 |        44 |     321 |         4 |       4 |     48 |         48 |     9 |           4 |
| 2501 |        51 |     336 |         6 |       6 |     57 |         57 |     8 |           6 |
| 3001 |        51 |     335 |         7 |       7 |     58 |         58 |     8 |           7 |
| 3501 |        49 |     334 |         8 |       8 |     57 |         57 |     6 |           8 |
| 4001 |        53 |     335 |         8 |       8 |     61 |         61 |     6 |           8 |
| 4501 |        55 |     336 |         8 |       8 |     63 |         63 |     6 |           8 |
| 5001 |        56 |     338 |         8 |       8 |     64 |         64 |     6 |           8 |
| 5501 |        58 |     338 |         8 |       8 |     66 |         66 |     5 |           8 |
| 6001 |        60 |     341 |         7 |       7 |     67 |         67 |     5 |           7 |
| 6501 |        60 |     338 |         7 |       7 |     67 |         67 |     5 |           7 |
| 7001 |        62 |     338 |         7 |       7 |     69 |         69 |     4 |           7 |
| 7501 |        67 |     341 |         9 |       9 |     76 |         76 |     2 |           9 |
| 8001 |        91 |     382 |         6 |       6 |     97 |         97 |     1 |           6 |
| 8501 |       109 |     394 |         2 |       2 |    111 |        111 |     0 |           2 |
| 9001 |       121 |     408 |         3 |       3 |    124 |        124 |     0 |           3 |
| 9501 |       113 |     419 |         1 |       1 |    114 |        114 |     0 |           1 |

Columns: `i_species`/`i_total` = inactive reactant species/count, `a_species`/`a_total` = active reactant species/count, reaction type counts are cumulative.

## Analysis

Three distinct phases are visible:

### Phase 1: Stable replication (reactions 1-1000)

The original 2 active reactants replicate steadily. Inactive species grow from 5 to ~43 as break products accumulate. Breaks and collisions grow in lockstep (~47 each by reaction 1000). Grabs are active (5-9) and transitions happening (2-4) — the Petri nets are functioning normally.

### Phase 2: Fragmentation and diversification (reactions 1000-7000)

Active reactants increase from 4 to 7-8 species — the original molecules broke into fragments that themselves fold into functional (though likely degraded) Petri nets. Inactive species creep up (43 to 62), total molecules grow slowly (321 to 338). The system is still somewhat functional — grabs drop (9 to 4), but transitions still happen.

### Phase 3: Collapse (reactions 7000-10000)

Dramatic shift around reaction 7500-8000: grabs drop to 0, active species crash to 1-3. Inactive species explode from 67 to 121, total molecules jump to 419. By reaction 9500, only 1 active species remains with 0 grabs — it can no longer grab ambient molecules to build copies. The system is effectively dead: breaks still happen but produce only inert fragments.

## Interpretation

The replicator initially worked well — grabbing ambient molecules (A, B, C, D, F), assembling them, and splitting copies. But cumulative break damage to the large active molecules eventually destroyed the replication machinery. Once the key grab/assemble/split Petri net structure was corrupted, the system couldn't self-repair and degraded into a soup of inert fragments.

This is the expected behavior for `endless_duplication` without mutation-driven repair mechanisms — entropy wins.

---

<details>
<summary>Initial state</summary>

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
  ],
  "env": {
    "transition_rate": 10,
    "grab_rate": 1,
    "break_rate": "1/1000000",
    "collision_rate": "1/100000"
  }
}
```

</details>

**Date:** 2026-03-08 | **Commit:** `62de28ce8d5b4e4e3b4b98cda3ad1a33c5225c33` (add commands)
